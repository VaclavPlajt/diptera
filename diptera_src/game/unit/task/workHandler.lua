

local workHandler={}


setmetatable(workHandler, require("game.unit.task.baseTaskHandler"));
workHandler.__index = workHandler;



function workHandler:init(minonController)
    self.minionController = minonController;
    
    self.requests = {};
    self.lastRequestId = 0;
    self.requestCount = 0;
    self.minions ={};
    self.freeMinions = {};
    self.workType = "work";
    self.lastNumOfWaitingReq = 0;
    self.numOfWaitingReq = 0;
    
    self.workUnitDelay = require("game.gameConst").minionWorkUnitDelay;
    
    return self;
end

--[[
-- request: {}
-- returns request id, it can be used to cancel request 
function workHandler:addWorkRequest(gr, gu, amount, onDelivery)
    self.lastRequestId = self.lastRequestId+1;
    local r = {
        gr=gr, gu= gu, amount = amount, 
        minions = {}, lastMinionID = 0, minionsCount = 0, 
        state ="waiting", onDelivery = onDelivery,
    };
    self.requests[self.lastRequestId] = r;
    return self.lastRequestId;
end
]]

-- request: {gr,gu,amount, onDelivery}
-- returns request id, it can be used to cancel request 
function workHandler:addWorkRequest(r)
    self.lastRequestId = self.lastRequestId+1;
       
    r.minions = {}; r.lastMinionID = 0; r.minionsCount = 0;
    r.state ="waiting"; 
    
    self.requests[self.lastRequestId] = r;
    self.requestCount = self.requestCount +1;
    --self.numOfWaitingReq = self.numOfWaitingReq +1;
    return self.lastRequestId;
end


function workHandler:handleWork()
    --self.requests = self.minContr:transportRequests
    self.numOfWaitingReq = 0;
    --print("Num of waiting  work requests: " .. self.lastNumOfWaitingReq);
    for id,request in pairs(self.requests) do
        self:doRequest(request, id);
    end
    
    self.lastNumOfWaitingReq = self.numOfWaitingReq; 
    
end

-- requests states:
---- "waiting" - task was created and is waiting in queue for free minions or different circumstances
---- "working" - task in progress
---- "canceled" - task is ready to be discarded
---- "done" -  task ws sucessfully completed and is ready to be discarded
function workHandler:doRequest(r, id)
    
    local state = r.state;
    
    if(state == "waiting") then
        if(self:addFreeMinionsToRequest(r, 1, nil)) then -- add free minions to request
            r.state = "working";
            --self.numOfWaitingReq = self.numOfWaitingReq -1;
            -- do work with assigned minions (states transitions ...)
            self:doMinionWork(r);
        end
        
        self.numOfWaitingReq = self.numOfWaitingReq +1;
        
    elseif(state == "working") then
        -- add free minions to request if any
        if(self.lastNumOfWaitingReq == 0) then
            self:addFreeMinionsToRequest(r, 1, nil)
        end
        
        -- do work with assigned minions (states transitions ...)
        self:doMinionWork(r);
        
    elseif(state=="done" or state == "canceled") then
        -- free all minions
        self:freeAllMinions(r);
        -- remove request
        self.requests[id] = nil;
        self.requestCount = self.requestCount - 1;
        --tell others
        Runtime:dispatchEvent{name="minionRequestEnd", action=self.workType, request = r};
    else
        print("Warning unrecognized transport request state !!");
    end
    
end


-- minion states during transport
---- "idle" - newly added to request or "transport" finished
---- "approaching" - on its way to item
---- "working" - moving with item to goal coordinates
---- "nextToWorkPlace" - moving with item to goal coordinates
function workHandler:doMinionWork(r)
    
    
    for index, minion in pairs(r.minions) do
        
        local state = minion.taskState;    
        
        if(state == "idle") then -- find item close to me and approach it 
            if(r.amount > 0 ) then
                local path =  self.minionController:findPathNextToGoal(r.gr,r.gu, minion); -- find path to work place
                
                if(path == nil) then -- workplace is not accessible 
                    
                    self:freeMinion(r, index);-- free minion to other work tasks
                    if(self.debPrnts) then print("pracovni misto je nedostupne"); end;
                    
                else
                    minion:setTaskState("approaching");
                    minion.taskData = nil;
                    local onFinish = function()
                        minion:setTaskState("nextToWorkPlace"); -- workplace reached
                    end;
                    
                    -- move minion to work place
                    minion:move(path,onFinish);
                end
                
            else -- nothing more to do
                self:freeMinion(r, index);-- free minion
            end
        elseif(state == "approaching") then 
            --moving towards workplace, do nothing
        elseif(state == "nextToWorkPlace") then -- pick up item and transport it to goal
            
            if( r.amount > 0) then -- work is still needed
                minion:setTaskState("working", r.gr,r.gu);
                local onFinish = function() 
                        if(r.amount > 0 ) then -- still needed
                            r.onDelivery(); 
                            r.amount = r.amount -1;
                            minion:setTaskState("nextToWorkPlace", r.gr,r.gu);
                        else -- no need for another work
                            self:freeMinion(r, index); -- free minion to other tasks
                        end
                    end
                minion.taskTimer = timer.performWithDelay(self.workUnitDelay, onFinish);
            else -- no more work is needed
                self:freeMinion(r, index); -- free minion to other tasks
            end
            
        elseif(state =="working")then
            -- minion is working, we will do nothing there
        else
            print("Warning: unrecognized minion task state in transport.")
        end
    end
    
    
    if(r.minionsCount == 0 and r.amount == 0) then
        --[[
        if(r.state=="waiting") then
            print("!! r.state==\"waiting\" and r.minionsCount == 0 and r.amount == 0")
            self.numOfWaitingReq = self.numOfWaitingReq -1;
        end
        ]]
        r.state = "done";
    end
    
end









return workHandler;


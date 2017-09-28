local transportHandler = {}


setmetatable(transportHandler, require("game.unit.task.baseTaskHandler"))
transportHandler.__index = transportHandler

function transportHandler:init(minionController)
    self.minionController = minionController;
    
    self.requests = {};
    self.lastRequestId = 0;
    self.requestCount = 0;
    self.minions ={};
    self.freeMinions = {};
    self.workType = "transport";
    self.lastNumOfWaitingReq = 0;
    self.NumOfWaitingReq = 0;
    return self;
end

-- request: {}
-- returns request id, it can be used to cancel request 
--[[
function transportHandler:addTransportRequest(gr, gu, amount, itemType, onDelivery)
    self.lastRequestId = self.lastRequestId+1;
    local r = {
        gr=gr, gu= gu, amount = amount, itemType=itemType,
        minions = {}, lastMinionID = 0, minionsCount = 0, 
        state ="waiting", onDelivery = onDelivery,
    };
    self.requests[self.lastRequestId] = r;
    return self.lastRequestId;
end
]]

function transportHandler:addTransportRequest(r)
    self.lastRequestId = self.lastRequestId+1;
    
    r.minions = {};
    r.lastMinionID = 0;
    r.minionsCount = 0;
    r.state ="waiting"; 
    
    self.requests[self.lastRequestId] = r;
    self.requestCount = self.requestCount +1;
    self.numOfWaitingReq = self.numOfWaitingReq +1;
    return self.lastRequestId;
end


function transportHandler:handleTransport()
    
    self.numOfWaitingReq = 0;
    --print("Num of waiting  repair requests: " .. self.lastNumOfWaitingReq);
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
function transportHandler:doRequest(r, id)
    
    local state = r.state;
    
    if(state == "waiting") then
        if(self:addFreeMinionsToRequest(r,1,nil)) then -- add free minions to request
            r.state = "working";
            --self.numOfWaitingReq = self.numOfWaitingReq -1;
            -- do work with assigned minions (states transitions ...)
            self:doMinionWork(r);
        end
        
        self.numOfWaitingReq = self.numOfWaitingReq +1;
        
    elseif(state == "working") then
        -- add free minions to request if any
        if(self.lastNumOfWaitingReq == 0) then
            self:addFreeMinionsToRequest(r,1,nil)
        end
        
        -- do work with assigned minions (states transitions ...)
        self:doMinionWork(r);
        
    elseif(state=="done" or state == "canceled") then
        -- return material minion are carying
        if(state == "canceled") then 
            self:returnAllMaterial(r);
        end 
        
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

function transportHandler:returnAllMaterial(r)
    for id,minion in pairs(r.minions) do
        local item = minion.taskData;
        if(item and item.addItem) then
            item:addItem(); -- return item
            minion.taskData = nil;
        end
    end
end

-- return material minion is carying 
function transportHandler:onMinionRemoval(minion)
    
    local item = minion.taskData;
    if(item and item.addItem) then
        item:addItem(); -- return item
        minion.taskData = nil;
    end
    
end

-- minion states during transport
---- "idle" - newly added to request or "transport" finished
---- "finished" - previous transpirt finished, but request is not done yet
---- "approaching" - on its way to item
---- "nextToItem" - minion reached tile nex to item, so it can be picked up
---- "transporting" - moving with item to goal coordinates
function transportHandler:doMinionWork(r)
    local noItemToTransport = false;
    
    for index, minion in pairs(r.minions) do
        
        local state = minion.taskState;
        
        
        if(state == "idle" or state == "finished") then -- find item close to me and approach it 
            if(r.amount > 0  and noItemToTransport== false) then
                local item, path = self.minionController:findPathtoCloseItemType(r.itemType, minion, r.bannedItem);-- find item to transport
                
                if(item == nil or path == nil) then -- if no accessible item on map 
                    noItemToTransport = true;
                    self:freeMinion(r, index);-- free minion to other transport tasks
                    if(self.debPrnts) then
                        if(item == nil) then
                            print("transportHandler, neni co transportovat.");
                        else
                            print("transportHandler, neni volna cesta k transportovanemu itemu.");
                        end
                    end
                    -- jak poznat kdy ma cely request cekat ?? kdy uvolnit vsechny miniony ??
                else
                    minion.taskData = item;
                    minion:setTaskState("approaching");
                    local onFinish = function()
                        minion:setTaskState("nextToItem", item.r, item.u); -- item reached
                    end;
                    
                    -- move minion to item,
                    minion:move(path,onFinish);
                end
            else -- nothing more to transport
                self:freeMinion(r, index);-- free minion
            end
        elseif(state == "approaching") then 
            --moving towards item, do nothing
        elseif(state == "nextToItem") then -- pick up item and transport it to goal
            local item = minion.taskData;
            local itemTaken = item:takeItem();
            local path =  self.minionController:findPathNextToGoal(r.gr,r.gu, minion);
            
            if(itemTaken and path and r.amount > 0) then
                
                minion:setTaskState("transporting",r.gr,r.gu);
                --local onFinish = function() minion:setToIdle(); r.onDelivery() end
                local onFinish = function()
                    if(r.amount > 0 ) then -- delivery still needed
                        r.onDelivery();
                        r.amount = r.amount -1;
                    elseif(itemTaken and item) then -- delivery not needed
                        item:addItem(); -- return item, note: if material item has been destroyed one piece of material is lost here
                    end
                    minion.taskData = nil;
                    minion:setTaskState("finished",r.gr,r.gu);
                end
                
                minion:move(path, onFinish); -- move to goal coordinates
                item:removeIfNeeded(); -- remove item from map, if nededed
            else -- no path to goal or no item to pick up
                if(itemTaken) then
                    item:addItem(); -- return item
                end
                
                -- no path from item to goal or transport is no longer needed but item cannot be taken here
                if(path==nil or r.amount <= 0 or itemTaken) then 
                    self:freeMinion(r, index); -- free minion to other tasks
                else 
                    --minion:setToIdle();
                    minion:setTaskState("finished");
                end
                
            end
            
        elseif(state =="transporting")then
            -- moving towards goal, do nothing
        else
            print("Warning: unrecognized minion task state:" .. state .. " in transport.")
        end
    end
    
    
    if(r.minionsCount == 0 and r.amount == 0) then
        r.state = "done";
    end
    
end



return transportHandler;


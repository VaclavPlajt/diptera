
-- contains functions shared by all task handlers
local baseTaskHandler ={}


baseTaskHandler.__index = baseTaskHandler;
baseTaskHandler.debPrnts = false;

-- adds minion to list of minions available to this task handler
function baseTaskHandler:addMinion(minion)
    minion:setToIdle();
    self.minions[#self.minions + 1 ] = minion;
    self.freeMinions[#self.freeMinions + 1] = minion;
    
    minion:setWorkType(self.workType)
end

-- removes minion from list of minions available to this task handler
-- returns removed minion
function baseTaskHandler:removeLastMinion()
    local minion = self.minions[#self.minions];
    self.minions[#self.minions] = nil;
    
    -- notify derived task handler 
    if(self.onMinionRemoval) then
        self:onMinionRemoval(minion);
    end
    
    -- remove it from free minions list, if present
    for index,freeMinion in pairs(self.freeMinions) do
        if(minion == freeMinion) then
            --self.freeMinions[index] = nil;
            table.remove(self.freeMinions,index);
            break;
        end
    end
    
    if(minion.request) then
        self:freeMinionFromRequest(minion.request, minion);
    end
    
    minion:setToIdle();
    minion:setWorkType("idle");
    return minion;
end

function baseTaskHandler:freeMinionFromRequest(r, minion)
    
    
    for index, minionInR in pairs(r.minions) do
        if( minion == minionInR) then
            r.minions[index] = nil;
            minion:assignToRequest(nil);
            r.minionsCount = r.minionsCount -1;
            
            
            if(r.minionsCount == 0 and r.state == "working") then
                r.state ="waiting";
                --self.numOfWaitingReq = self.numOfWaitingReq +1;
            end
            
        end
    end
    
end


function baseTaskHandler:freeMinion(r, index)
    local minion = r.minions[index];
    r.minions[index] = nil;
    
    minion:setToIdle();
    self.freeMinions[#self.freeMinions + 1] = minion;
    r.minionsCount = r.minionsCount -1;
end

function baseTaskHandler:freeAllMinions(r)
    
    for id,minion in pairs(r.minions) do
        r.minions[id] = nil;
        minion:setToIdle();
        self.freeMinions[#self.freeMinions + 1] = minion;
        r.minionsCount = r.minionsCount -1;
    end
end


-- adds free minions to given request
-- no more minions then requests need to be completed ASAP are added
-- return false when no minions where added to request
-- maxIncrease - optional, max number of minions which can assigned to the request in call
-- maxMinions - optional, mas number of minions assigned to request 
function baseTaskHandler:addFreeMinionsToRequest(r, maxIncrease, maxMinions)
    local retVal = false;
    local maxAddCount = r.amount - r.minionsCount;
    
    if(maxIncrease and maxAddCount > maxIncrease) then
        maxAddCount = maxIncrease;
    end
    
    if(maxMinions and maxAddCount + r.minionsCount > maxMinions) then
        maxAddCount = maxMinions - r.minionsCount;
    end
    --[[
    if(maxRequestminionCount and r.minionsCount + maxAddCount > maxRequestminionCount) then
        maxAddCount = maxRequestminionCount - r.minionsCount;
    end
    ]]
    
    local freeMinions = self.freeMinions;
    
    while(maxAddCount > 0 and #freeMinions > 0) do
        local minion = freeMinions[#freeMinions];
        freeMinions[#freeMinions] = nil;
        
        r.lastMinionID = r.lastMinionID +1;
        r.minions[r.lastMinionID] = minion;
        maxAddCount = maxAddCount -1; -- each minion can transport one item or deliver one unit of work
        r.minionsCount = r.minionsCount +1;
        minion:assignToRequest(r);
        retVal = true;
    end
    
    --if(not retVal) then print("No minion added to task.") end
    
    return retVal;
end

function baseTaskHandler:printState()
    print("-- task handler: " .. self.workType);
    print(#self.freeMinions .. " out of  " .. #self.minions .. " minions free" );
    print(self.requestCount .. " requests");
end

-- will remove all minions
-- will cancels and remove all requests from task handler
function baseTaskHandler:restart()
    
    while(#self.minions > 0) do
        self:removeLastMinion();
    end
    
    for id, r in pairs(self.requests) do
        r.state = "canceled";
        
        --tell others
        Runtime:dispatchEvent{name="minionRequestEnd", action=self.workType, request = r};
    end
    
    self.requests = {};
    self.lastRequestId = 0;
    self.requestCount = 0;
    
end
return baseTaskHandler;


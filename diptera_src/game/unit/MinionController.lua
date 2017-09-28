

local MinionController = {}

local abs = math.abs;
local max = math.max;


local debugTaskHandlers =  false;

function MinionController:new(isoGrid, map, pathFinder , context,  player)
    local newMinionController = {};
    
    -- set meta tables so lookups will work
    setmetatable(newMinionController, self);
    self.__index = self;
    
    
    newMinionController.isoGrid = isoGrid;
    newMinionController.map =  map;
    newMinionController.pathFinder = pathFinder;
    newMinionController.minions = {};
    newMinionController.unassignedMinions = {};
    newMinionController.player = player;
    --newMinionController.isoMapGraphics =isoMapGraphics;
    
    newMinionController.img =  context.img;
    --newMinionController.minionLayer = isoMapGraphics.minionLayer;

    -- transport 
    newMinionController.transportHandler = require("game.unit.task.transportHandler"):init(newMinionController);
    newMinionController.workHandler = require("game.unit.task.workHandler"):init(newMinionController);
    newMinionController.repairHandler = require("game.unit.task.repairHandler"):init(newMinionController);
    
    newMinionController.updateNum = 0;
    
    
    -- add listener to chane assigement requests
    newMinionController.changeAssigmnentListener = function(event) newMinionController:onAssignRequestEvent(event) end;
    Runtime:addEventListener("minionAssigmentRequest", newMinionController.changeAssigmnentListener);
    
    
    return newMinionController;
end

-- will clear all minions and requests
-- sets new map
function MinionController:restart(newMap)
    
    -- restart all task handlers 
    self.transportHandler:restart();
    self.workHandler:restart();
    self.repairHandler:restart();
    
    -- clear all minions
    self.minions = {};
    self.unassignedMinions = {};
    self:broadCastMinionAssigmentChanged();
    
    -- use new map
    self.map =  newMap;
end


function MinionController:destroy()
    
    self:restart(nil);
    Runtime:removeEventListener("minionAssigmentRequest", self.changeAssigmnentListener);
    
end


-- request: {gr, gu, amount, itemType, onDelivery}
--function MinionController:addTransportRequest(gr, gu, amount, itemType, onDelivery)
function MinionController:addTransportRequest(request)
    --return self.transportHandler:addTransportRequest(gr, gu, amount, itemType, onDelivery);
    return self.transportHandler:addTransportRequest(request);
end

--function MinionController:addWorkRequest(gr, gu, amount, onDelivery)
function MinionController:addWorkRequest(r)
    --return self.workHandler:addWorkRequest(gr, gu, amount, onDelivery)
    self.workHandler:addWorkRequest(r);
end

function MinionController:addRepairRequest(r)
    --return self.workHandler:addWorkRequest(gr, gu, amount, onDelivery)
    self.repairHandler:addRepairRequest(r);
end

function MinionController:updateTasks()
    self.updateNum = self.updateNum  +1;
    self.transportHandler:handleTransport();
    self.workHandler:handleWork();
    self.repairHandler:handleRepairs();
    
    if(debugTaskHandlers and self.updateNum%50 == 0) then
        print(" ----------------");
        print("# of minions: " .. #self.minions);
        self.transportHandler:printState();
        self.workHandler:printState();
        self.repairHandler:printState();
    end
    
end

function MinionController:moveMinonsFromEnemyClusters()
    local map = self.map;
    local humanPlayer = self.player;
    
    for index, minion in pairs(self.minions) do
        local r,u = minion:getIsoCoord();
        local tileOwner = map:getTileOwner(r, u);
        
        -- minion is on enemy cluster so move it
        if(tileOwner and tileOwner.isAI) then
            --print("moving minion away of enemy cluster")
            
            local clusterNum = humanPlayer:getRandomOwnedClusterNumber();
            local r,u = map:getRandomFreeTileInClususter(clusterNum);
            
            minion:forcePosition(r,u);
        end
    end    
end

-- recives and handle following request
--* "minionAssigmentRequest" - braodcasted when user inputs request to chnge minion assigments
--    -   change - "add"/"remove" - ad or remove minion from work type assigment
--    -   workType - work type name
function MinionController:onAssignRequestEvent(event)
    --print("MinionController:assignRequestEvent(event)");
    
    local change =  event.change;
    local workType =  event.workType;
    
    
    --minionWorkTypes = {"repair","work", "transport", "idle"},
    
    
    if(change == "remove") then
        
        local taskHandler;
        
        if(workType == "repair") then
            taskHandler = self.repairHandler;
        elseif(workType == "work") then
            taskHandler = self.workHandler;
        elseif(workType == "transport") then
            taskHandler = self.transportHandler;
        elseif(workType == "idle") then  
            print("Cannot assign minion to idle or from idle directly !");
            return;
        else
            print("Warning: Unknown work type: " .. workType .. "!");
            return;
        end
        
        if(#taskHandler.minions > 0)then
            local minion = taskHandler:removeLastMinion();
            -- add minion to unassigned list
            local unassigned = self.unassignedMinions;
            unassigned[#unassigned +1] = minion;
            
            self:broadCastMinionAssigmentChanged();
        else
            print("No minion to remove from task handler.")
        end
        
    elseif(change== "add") then
        
        self:assignMinionToWorkType(workType)
        
    else
        print("Warning: MinionController - unrecognized minion assignt request type.")
    end
end


function MinionController:assignMinionToWorkType(workType)
    
    local unassigned = self.unassignedMinions;
    
    if(#unassigned <= 0)then
        print("no unassigned minion to assign to " .. workType);
        return;
    end
    
    local minion = unassigned[#unassigned];
    
    --minionWorkTypes = {"repair","work", "transport", "idle"},
    if(workType == "repair") then
        self.repairHandler:addMinion(minion);
    elseif(workType == "work") then
        self.workHandler:addMinion(minion);
    elseif(workType == "transport") then
        self.transportHandler:addMinion(minion);
    elseif(workType == "idle") then  
        print("Cannot assign minion to idle directly !");
        return;
    else
        print("Warning: Unknown work type: " .. workType .. "  to assign!");
        return;
    end
    
    unassigned[#unassigned] = nil;
    self:broadCastMinionAssigmentChanged();
    
end

function MinionController:addMinion(minion, tellOthers)
    
    -- add minion to list of all minions
    self.minions[#self.minions +1] = minion;
    
    -- add minion to unassigned list
    local unassigned = self.unassignedMinions;
    unassigned[#unassigned +1] = minion;
    
    if(tellOthers) then
        self:broadCastMinionAssigmentChanged(1);
    else
        self:broadCastMinionAssigmentChanged();
    end
    
end

function MinionController:broadCastMinionAssigmentChanged(added)
    --* "minionAssigmentChanged" - broadcasted by minion controller, when minions are assigned to new work
    --    - assigments - new table of assigments
    
    local assigments =  {
        idle =  #self.unassignedMinions,
        transport = #self.transportHandler.minions,
        work = #self.workHandler.minions,
        repair = #self.repairHandler.minions,
    }
    
    -- broadcast
    Runtime:dispatchEvent{name="minionAssigmentChanged",assigments=assigments, added=added};
end

function MinionController:createStartMinions(count)
    
    for i = 1, count do
        --local clusterNum = self.player:getRandomOwnedClusterNumber();
        local clusterNum = self.player.homeCluster;
        local r,u = self.map:getRandomFreeTileInClususter(clusterNum);
        
        --local cluster = self.map.clusters[clusterNum];
        --local tileCoord = cluster.tiles[ math.random(1,#cluster.tiles)];
        
        local minion = require("game.unit.Minion"):new(r,u,self.isoGrid);
        self:addMinion(minion)
        
        --[[
        if(i%3 == 0) then
            self:assignMinionToWorkType("repair");
        elseif(i%3 == 1) then
            self:assignMinionToWorkType("work");
        else
            self:assignMinionToWorkType("transport");
        end
        --]]
    end
end


function MinionController:addMaterialRequest(gr, gu, amount, onDeliveryFun)
    -- dispatch request to transport handler
    self.transportHandler:addTransportRequest(gr, gu, amount, "Material", onDeliveryFun);
end


function MinionController:canMinionAccessTile(r,u)
    local map = self.map;
    local size = map.size;
    
    if(u > 0 and u <= size and r >0 and r <= size) then 
        --local minion  = self.cPathMinion; -- get current minion
        local currentPlayerId = self.player.id;
        local tile = map.tiles[r][u];
        local clusterNum = tile.cluster
        local tileOwner = map.clusters[clusterNum].owner;
        --[[
        local item = nil;
        
        if(tile.item > 0) then
            item = map:getItem(tile.item);
        end
        ]]
        
        -- minion can acces the tile when there is no item or and tile is owned by current player
        --if((item == nil or item.typeName == "BuildingSite") and ((tileOwner == currentPlayerId) or tileOwner < 0) ) then
        if((tile.item <=0) and ((tileOwner == currentPlayerId) or tileOwner < 0) ) then
            return true;
        end
        
    end
    
    return false;
end
local count = 0;

function MinionController:addRandomMaterialMoveRequests()
    for i=1,7 do
        --addMaterialRequest(gr, gu, amount, onDeliveryFun)
        local clusterNum = self.player:getRandomOwnedClusterNumber();
        local cluster = self.map.clusters[clusterNum];
        local gatherPoint = cluster.tiles[ math.random(1,#cluster.tiles)];
        
        --self.isoMapGraphics:colorTile(gatherPoint[1],gatherPoint[2], {0.0,0.0,1,1})
        
        self:addMaterialRequest(gatherPoint[1], gatherPoint[2], i, function() count=count+1; print("Material #".. count .. " delivered!") end);
    end
end




local function isNextToGoal(gr, gu, cNode)
    local cr, cu = cNode[1], cNode[2];
    
    local dist = max(abs(cr-gr),abs(cu-gu)); -- 8 adecent tiles
    --local dist = abs(cr-gr)+abs(cu-gu); -- 4 adjecent tiles
    
    if(dist <= 1) then -- nevim co se stane kdyz misto <= dam ==
        return true;
    end
    
    return false;
end

-- path = nil
-- n = 1
-- while path==nil
-- find n-th clostest item
-- path = path to item entry point (any neighbouring tile)
-- n= n+1;
-- returns moving state, found item
-- return true when successful, false otherwise (e.g. item canno be found or is inaccessible)
function MinionController:moveMinionNextToCloseItemType(itemTypeName, minion, onFinished)
    
    local moving = false;
    local item;
    local n = 1;
    
    local r,u = minion:getIsoCoord();
    
    while moving==false do
        item = self.map:findnNthClosestItem(itemTypeName, r, u, n);
        if(not item) then
            return false;
        end
        
        local gr, gu = item.r, item.u;
        --[[
        path = self.pathFinder:findPath(r,u,gr,gu,
        function(r,u) return self:canMinionAccessTile(r,u) end,
        function(cNode) return isNextToGoal(gr,gu,cNode) end
        , false);
        ]]
        
        moving = self:moveMinionNextToGoal(gr,gu, minion, onFinished)
        
        n = n+1;
    end
    
    return moving, item;
    
end

-- path = nil
-- n = 1
-- while path==nil
-- find n-th clostest item
-- path = path to item entry point (any neighbouring tile)
-- n= n+1;
-- returns found item
-- may return nil, nil when there is no item or no item can be accessed
function MinionController:findPathtoCloseItemType(itemTypeName, minion, bannedItem)
    
    local path = nil;
    local item;
    local n = 1;
    
    local r,u = minion:getIsoCoord();
    
    while path==nil do
        item = self.map:findnNthClosestItem(itemTypeName, r, u, n);
        if(not item) then
            return nil,nil;
        end
        
        if(item ~= bannedItem) then
            local gr, gu = item.r, item.u;
            
            path = self.pathFinder:findPath(r,u,gr,gu,
            function(r,u) return self:canMinionAccessTile(r,u) end,
            function(cNode) return isNextToGoal(gr,gu,cNode) end
            , false);
        end
        
        --path = self:moveMinionNextToGoal(gr,gu, minion, onFinished)
        
        n = n+1;
    end
    
    return item, path;
    
end


-- returns path which leads from current minions position to goal or nil when path cannot be found
function MinionController:findPathNextToGoal(gr,gu, minion)
    local sr,su  = minion:getIsoCoord();
    
    local path = self.pathFinder:findPath(sr,su,gr,gu,
    function(r,u) return self:canMinionAccessTile(r,u) end,
    function(cNode) return isNextToGoal(gr,gu,cNode) end,
    false);
    
    
    return path;
end

-- returns true when path found and movement was initiated, false otherwise
--[[
function MinionController:moveMinionNextToGoal(gr,gu, minion, onFinished)
    local r,u  = minion:getIsoCoord();
    local path = self.pathFinder:findPath(r,u,gr,gu,
    function(r,u) return self:canMinionAccessTile(r,u) end,
    function(cNode)return isNextToGoal(gr,gu,cNode) end
    ,false);
    
    if(path) then
        minion:move(path, onFinished);
        
        if(showPaths) then
            self:showPath(path);
        end
        return true;
    else
        return false;
    end
end
]]

-- returns true when path found and movement was initiated, false otherwise
function MinionController:moveMinionToGoal(gr,gu, minion, onFinish)
    local r,u  = minion:getIsoCoord();
    local path = self.pathFinder:findPath(r,u,gr,gu,
    function(r,u) return self:canMinionAccessTile(r,u) end,
    nil, false);
    if(path) then
        minion:move(path, onFinish);
        if(showPaths) then
            self:showPath(path);
        end
        return true;
    else
        return false;
    end
end


return MinionController;


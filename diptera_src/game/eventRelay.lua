
local eventRelay = {}


function eventRelay:init(game, map, minionController, humanPlayer ,mapGrapics)
    self.map = map;
    self.minionController = minionController;
    self.playerId = humanPlayer.id;
    self.mapGraphics = mapGrapics;
    self.userActions = require("game.UserActions"):new(game,minionController, map);
    self.lastSelectedR = -1;
    self.lastSelectedU = -1;
    self.lastTappedR = -1;
    self.lastTappedU = -1;
    self.lastSelectedItem  = nil;
    
    self.tileTappedListener = function(event) self:onTileTapped(event) end;
    Runtime:addEventListener("tiletapped", self.tileTappedListener);
    
    self.actionSelectedListener = function(event) self:onActionSelected(event) end;
    Runtime:addEventListener("actionSelected", self.actionSelectedListener);
    
    self.minionActionRequestedListener = function(event) self:onMinionActionRequested(event) end;
    Runtime:addEventListener("minionActionRequest", self.minionActionRequestedListener);
    
    self.minionRequestEndList = function(event) self:onMinionActionRequestedEnd(event) end;
    Runtime:addEventListener("minionRequestEnd", self.minionRequestEndList);
    
    -- events which may change selection listeners
    self.newBuildingListener = function(event)  self:onNewBuildingCreated(event) end;
    Runtime:addEventListener("buildingCreated", self.newBuildingListener);
    
    
    return self;
end


function eventRelay:restart(newMap, newMapGraphics)
    self.map = newMap;
    self.mapGraphics = newMapGraphics;
    self.userActions:restart(newMap);
    self:dispatchNoActionsAvailable();
end

function eventRelay:destroy()
    self.map = nil;
    self.mapGraphics = nil;
    self.userActions:destroy();
    self.userActions = nil;
    
    -- remove all listeners
    Runtime:removeEventListener("tiletapped", self.tileTappedListener);
    Runtime:removeEventListener("actionSelected", self.actionSelectedListener);
    Runtime:removeEventListener("minionActionRequest", self.minionActionRequestedListener);
    Runtime:removeEventListener("minionRequestEnd", self.minionRequestEndList);
    Runtime:removeEventListener("buildingCreated", self.newBuildingListener);
    
    self:dispatchNoActionsAvailable();
end


function eventRelay:onTileTapped(event)
    
    --[[
    if(self:isTapEventBlocked(event)) then
        return;
    end
    ]]
    
    -- get tile from map
    local map = self.map;
    --local size = map.size;
    local r, u = event.r, event.u;
    self.lastTappedR,  self.lastTappedU  = r, u;
    self.lastSelectedR = -1;
    self.lastSelectedU = -1;
    
    if(self.userActions.waitingToTileSelection) then        
        self.mapGraphics:showSelection(r,u,false);
        self.userActions:doTileSelectedUserActions(event, self);
        self.lastSelectedR = r;
        self.lastSelectedU = u;
        return;
    end
    
    local tile = map.tiles[r][u];
    
    
    if(tile.item and tile.item > 0) then
        local item = map:getItem(tile.item);
        self.mapGraphics:showSelection(r,u,true);
        
        if(self.userActions:itemSelected(event, self, item, self.lastSelectedItem)) then
            self:dispatchItemSelectedEvents(item,tile);
        else
            return;
        end
        
        self.lastSelectedR = r;
        self.lastSelectedU = u;
        if(self.lastSelectedItem and self.lastSelectedItem ~= item and self.lastSelectedItem.onDeselection) then
            self.lastSelectedItem:onDeselection()
        end
        self.lastSelectedItem  = item;
    else
        if(self.lastSelectedItem and self.lastSelectedItem ~= item and self.lastSelectedItem.onDeselection) then
            self.lastSelectedItem:onDeselection()
        end
        
        self.lastSelectedItem  = nil;
        self.mapGraphics:showSelection(r,u,false);
        self:dispatchEmptyTileSelectedEvents(r,u, tile);
    end
end

function eventRelay:dispatchNoActionsAvailable()
    Runtime:dispatchEvent{name="actionsAvailable", actions=""};
end

function eventRelay:dispatchActionsAvailable(actionsName, params)
    Runtime:dispatchEvent{name="actionsAvailable", actions=actionsName, params=params};
end

function eventRelay:dispatchWrongTileSelected(event)
    self.mapGraphics:showWrongSelection(event.r,event.u);
end

function eventRelay:dispatchItemSelectedEvents(item, tile)
    
    local map = self.map;
    local onTile = tile or map.tiles[item.r][item.u];
    
    local owned = (map.clusters[onTile.cluster].owner == self.playerId);
    
    local params = {item=item, owned=owned};
    
    -- remember it
    self.lastSelectedR = item.r;
    self.lastSelectedU = item.u;
    if(self.lastSelectedItem and self.lastSelectedItem ~= item and self.lastSelectedItem.onDeselection) then
        self.lastSelectedItem:onDeselection() -- deselect previously selected item
    end
    self.lastSelectedItem  = item;
    
    -- tell it to the item
    item:onSelection();
    
    -- tell others
    Runtime:dispatchEvent{name = "mapItemSelected",typeName = item.typeName, params=params}
    
    -- show appropriate user actions
    Runtime:dispatchEvent{name="actionsAvailable", actions="itemSelected", params=params};
end

function eventRelay:dispatchEmptyTileSelectedEvents(r,u, tile)
    local params = {r=r,u=u}
    
    local mTile = tile or self.map.tiles[r][u];
    
    if(self.map.clusters[mTile.cluster].owner == self.playerId) then
        Runtime:dispatchEvent{name="actionsAvailable", actions="myEmptyTileSelected", params=params}; 
    else
        Runtime:dispatchEvent{name="actionsAvailable", actions="oponentEmptyTileSelected", params=params}; 
    end
end


-- called when user choose one of avalable optons
function eventRelay:onActionSelected(event)
    --[[
    if(self:isUserActionBlocked(event)) then
        return;
    end
    ]]
    
    self.userActions:doUserAction(event, self);
    
end

-- relyes minion work requesrts to minion controller
function eventRelay:onMinionActionRequested(event)
    
    local action = event.action;
    
    if(action == "work") then
        --print("eventHandler: handle work request");
        self.minionController:addWorkRequest(event.request);
    elseif(action == "transport") then
        --print("eventHandler: handle transport request");
        self.minionController:addTransportRequest(event.request);
    elseif(action == "repair") then
        self.minionController:addRepairRequest(event.request);
    else
        print("EventRelay Warning: unknown minion task action: " .. tostring(action));
        return;
    end
    
    self.mapGraphics:addRequestMark(action, event.request);
    
end

function eventRelay:onMinionActionRequestedEnd(event)
    --local action = event.action;
    self.mapGraphics:removeRequestMark(event.request);
    
end

function eventRelay:onNewBuildingCreated(event)
    
    if(self.lastSelectedR > 0 and self.lastSelectedU > 0 
        and event.building.r == self.lastSelectedR and self.lastSelectedU == event.building.u and
        not self.userActions.waitingToTileSelection) then
        
        self:onTileTapped{r = self.lastSelectedR, u=self.lastSelectedU};
    end
end

--[[
function eventRelay:isTapEventBlocked(event)
    return false;
end

function eventRelay:isUserActionBlocked(event)
    return false;
end
]]

function eventRelay:clusterChangedOwner(clusterNum)
    
    --print("eventRelay:clusterChangedOwner()")
    
    -- player already tapped somwhere on map
    if(self.lastTappedR > 0 and self.lastTappedU > 0) then
        local selCluster = self.map.tiles[self.lastTappedR][self.lastTappedU].cluster;
        
        -- last tapp lies in chluster which changed owner
        if(selCluster == clusterNum) then
            self.userActions:cancelWaitForTileSelection();
            self.lastSelectedItem = nil;
            self:onTileTapped{r = self.lastTappedR, u=self.lastTappedU};
        end
    end
    
end

return eventRelay;


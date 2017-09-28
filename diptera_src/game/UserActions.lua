-- object serving as an collection of functions for execution of user initiated in-gmae action


local UserActions ={}

local generalActionsHolder = {};
local tileSelectedActionsHolder = {};

function UserActions:new(game,minionController, map)
    local newUserActions = {};
    
    -- set meta tables so lookups will work
    setmetatable(newUserActions, self)
    self.__index = self
    
    self.deconstructMaterialReturnRatio = require("game.gameConst").deconstructMaterialReturnRatio;
    
    newUserActions.minionController = minionController;
    --newUserActions.aIPlayerBehavior = gameState.aIPlayerBehavior;
    --newUserActions.humanPlayerAutomation = gameState.humanPlayerAutomation;
    newUserActions.map = map;
    newUserActions.game = game;
    
    --newUserActions.aiPlayer = gameState.aiPlayer;
    --newUserActions.humanPlayer = gameState.humanPlayer;
    
    newUserActions.waitingToTileSelection = false; 
    newUserActions.preEvent = nil;
    
    newUserActions.isAvaitingTileSelection = false;
    
    return newUserActions;
end

function UserActions:startBuild(r,u,buildingType)
    return require("game.map.buildings.BuildingSite"):new(r,u,self.map, buildingType, self.minionController);
end

function UserActions:restart(newMap)
    self.map = newMap;
    self:cancelWaitForTileSelection();
end

function UserActions:destroy()
    self.map = nil;
end

-- do general user actions
function UserActions:doUserAction(event, eventRelay)
    
    local action = event.action;
    --print("User Action: " .. action)
    
    if(generalActionsHolder[action]) then
        generalActionsHolder[action](self,eventRelay, event); -- (userActions, eventRelay, event)
    else
        print("general user action: " .. tostring(action) .. " not found!!");
    end
end

-- actions which need to select target tile, they have previous state
function UserActions:doTileSelectedUserActions(event, eventRelay)
    local action = self.preEvent.action;
    
    if(tileSelectedActionsHolder[action]) then
        tileSelectedActionsHolder[action](self,eventRelay, event, self.preEvent); -- (userActions, eventRelay, event, previousEvent)
    else
        print("tile selection user action: " .. tostring(action) .. " not found!!");
        self:cancelWaitForTileSelection();
    end
end


function UserActions:setWaitForTileSelection(event)
    self.waitingToTileSelection = true;
    self.preEvent = event;
end

function UserActions:cancelWaitForTileSelection()
    self.waitingToTileSelection = false; 
    self.preEvent = nil;
end

function UserActions:itemSelected(event, eventRelay, item, previousItem)
    
    if(previousItem and previousItem.typeName == "Gun" and item and item.typeName == "EnemyKeep") then
        --print("set target ...")
        -- call st target with fake previous event
        tileSelectedActionsHolder.setTarget(self,eventRelay, event,{params = {item=previousItem}});
        return false;
    end
    
    return true;
end

---------------------------- Genaral purpouse actions ----------------------------

function generalActionsHolder.pauseGame(userActions, eventRelay, event)
    userActions.game:pause();
end

function generalActionsHolder.resumeGame(userActions, eventRelay, event)
    userActions.game:resume();
end

function generalActionsHolder.buildWalls(userActions, eventRelay, event)
    local params = event.params;
    local buildingSite = userActions:startBuild(params.r,params.u,"Wall");
    
    -- start buildin walls chain 
    --userActions:setWaitForTileSelection(event);
    --eventRelay:dispatchActionsAvailable("Wall_building_actions", event.params);
    
    eventRelay:dispatchItemSelectedEvents(buildingSite);
end

function generalActionsHolder.buildGun(userActions, eventRelay, event)
    local params = event.params;
    local buildingSite = userActions:startBuild(params.r,params.u,"Gun");
    -- select building site
    eventRelay:dispatchItemSelectedEvents(buildingSite) ;
end


-- destroy selected item
function generalActionsHolder.destroy(userActions, eventRelay, event)
    
    local item = event.params.item;
    if(item and item.deconstruct) then
        item:deconstruct();
    else
        print("UserActions: selected item cannot be deconstructed");
    end
end


function generalActionsHolder.cancel(userActions, eventRelay, event)
    
    local item = event.params.item;
    
    if(item and item.typeName == "BuildingSite" and item.deconstruct) then
        item:destroy();
        -- show no action
        return eventRelay:dispatchNoActionsAvailable();
    else
        print("UserActions: unknown cancel action");
    end
end


function generalActionsHolder.setTarget(userActions, eventRelay, event)
    -- show appropriate user actions
    eventRelay:dispatchActionsAvailable("chooseTarget", event.params);
    -- wait for user selecting target
    userActions:setWaitForTileSelection(event);
end

function generalActionsHolder.stopFiring(userActions, eventRelay, event)
    
    local gun = event.params.item;
    gun:stopFiring();
end

-- destroyed keep conversion
function generalActionsHolder.convert(userActions, eventRelay, event)
    
    local destroyedKeep =  event.params.item;
    destroyedKeep:requestConversion();
end

-- disable building repairing
function generalActionsHolder.disableRepair(userActions, eventRelay, event)
    local building =  event.params.item;
    
    building:setRepairEnabled(false);
    
end

-- enables building repairs
function generalActionsHolder.enableRepair(userActions, eventRelay, event)
    local building =  event.params.item;
    
    building:setRepairEnabled(true);
    
end


-- stop destroyed keep conversion
function generalActionsHolder.stopConversion(userActions, eventRelay, event)
    local destroyedKeep =  event.params.item;
    destroyedKeep:cancelConversion();
end

-- stop building wall chain
function generalActionsHolder.cancelWallBuild(userActions, eventRelay, event)
    
    userActions:cancelWaitForTileSelection();
    --Runtime:dispatchEvent{name="actionsAvailable", actions="", params=params};
    eventRelay:dispatchNoActionsAvailable();
end

function generalActionsHolder.cancelTargeting(userActions, eventRelay, event)
    -- select the gun again
    local previousEvent = userActions.preEvent;
    local gun = previousEvent.params.item; 
    userActions:cancelWaitForTileSelection();
    eventRelay:dispatchItemSelectedEvents(gun);
    
end

function generalActionsHolder.bringMaterialHere(userActions, eventRelay, event)
    
    local params = event.params;
    
    if(not params.item) then
        local tile = userActions.map.tiles[params.r][params.u];
        if(tile.item > 0) then
            local item = userActions.map:getItem(tile.item);
            
            if(item.typeName ~= "Material") then
                print("UserAction Warning: cannot bring material to item:" .. tostring(item.typeName));
                return;
            else
                params.item = item;
            end
        end
    end
    -- save eventa params (tile coordinates and sometimes selected material item)
    userActions.preEvent = event;
    -- show appropriate user actions
    eventRelay:dispatchActionsAvailable("bringMaterialHere", event.params);
    
end

local function sentMaterialTransportRequest(r,u,amount, materialItem,map, eventRelay)
    
    if(materialItem) then 
        if(materialItem.typeName == "Material") then
            r = materialItem.r;
            u = materialItem.u;
        else
            print("UserActions Warning, cannot bring material to item :" .. tostring(materialItem.typeName));
            return;
        end
    else
        -- create new material with 0 amount
        materialItem = require("game.map.items.Material"):new(r,u,0,map);
    end
    
    -- send transport request
    local request = {gr=r,gu=u,amount=amount,itemType="Material",bannedItem = materialItem,
    onDelivery = function() materialItem:addItem(true) end}
    materialItem.bringHereRequest = request;
    
    eventRelay:onMinionActionRequested{name="minionActionRequest", action="transport", request = request};
    
end

-- material transport request
function generalActionsHolder.bringMaterial(userActions, eventRelay, event)
    
    local preEventParams = userActions.preEvent.params;
    local item = preEventParams.item;
    local count = event.params.count;
    
    if(count > 0) then 
        sentMaterialTransportRequest(preEventParams.r,preEventParams.u,count,  item,userActions.map, eventRelay);
    end
    eventRelay:dispatchNoActionsAvailable();
end



-- calcel material delivery to seleted tile
function generalActionsHolder.cancelBringHereRequest(userActions, eventRelay, event)
    local material = event.params.item;
    material:cancelBringHereRequest();
end

function generalActionsHolder.unlockTreasure(userActions, eventRelay, event)
    local treasure = event.params.item;
    treasure:sendWorkRequest();
end

function generalActionsHolder.stopUnlockingTreasure(userActions, eventRelay, event)
    local treasure = event.params.item;
    treasure:cancelWorkRequest();
end

--{"help", "reset", "close"}
function generalActionsHolder.help(userActions, eventRelay, event)
    userActions.game.gameGraphics.helpLayerUI:show()
end


function generalActionsHolder.resetGame(userActions, eventRelay, event)
    userActions.game:restartGame();
end

function generalActionsHolder.closeGame(userActions, eventRelay, event)
    local rootGroup = userActions.game:getRootGroup();
    local contentGroup = userActions.game:getContentGroup();
    local context = userActions.game.context;
    
    userActions.game:destroyGame();
    
    require("ui.main.MainMenu"):new(rootGroup,contentGroup, context, true);
end

function generalActionsHolder.uiOff(userActions, eventRelay, event)
    userActions.game.gameGraphics:hideUI(15000)
end

function generalActionsHolder.zoomIn(userActions, eventRelay, event)
    userActions.game.gameGraphics.playerInput:scaleIn()
end

function generalActionsHolder.zoomOut(userActions, eventRelay, event)
    userActions.game.gameGraphics.playerInput:scaleOut()
end

---------------------------- Tile selection actions (targeting, chain building etc.) ----------------------------



-- set target of previously selected gun to now selected tile if is occupied by legal target
function tileSelectedActionsHolder.setTarget(userActions, eventRelay, event, previousEvent)
    
    local map = userActions.map;
    local selectedTile = map.tiles[event.r][event.u];
    local selectedItem = map:getItem(selectedTile.item);
    
    -- target have to be an item
    if(not selectedItem) then
        eventRelay:dispatchWrongTileSelected(event);
        return;
    end;
    
    -- target can be an item only of certain types
    if( not (selectedItem.typeName == "EnemyKeep" or selectedItem.typeName == "Wall") ) then
        eventRelay:dispatchWrongTileSelected(event);
        return;
    end
    
    local targetingGun = previousEvent.params.item;
    local gunClusterNum = map.tiles[targetingGun.r][targetingGun.u].cluster;
    local gunCluster = map.clusters[gunClusterNum];
    local isAdjecentCluster =  gunCluster.neighbors[selectedTile.cluster];
    
    if(isAdjecentCluster) then
        targetingGun:setTarget(selectedItem);
        userActions:cancelWaitForTileSelection();
        eventRelay:dispatchItemSelectedEvents(targetingGun);
    else
        eventRelay:dispatchWrongTileSelected(event)
        return;
    end
    
    --self:dispatchItemSelectedEvents(preSelectedGun);
    --eventRelay:dispatchNoActionsAvailable();
end


function tileSelectedActionsHolder.buildWalls(userActions, eventRelay, event, previousEvent)
    local map = userActions.map;
    local r,u = event.r, event.u;
    local tile = map.tiles[r][u];
    
    --[[
    if(tile.item > 0) then
        eventRelay:dispatchWrongTileSelected(event);
        return;
    end
    ]]
    
    -- free tile selected, chech ownership and build wall block
    local owner = map:getTileOwner(r, u);
    if(tile.item <= 0 and owner and  owner.isAI == false) then
        --print("wall in chaing build ...")
        local buildingSite = userActions:startBuild(r,u,"Wall");
    else
        
        --eventRelay:dispatchWrongTileSelected(event);
        
        if(tile.item > 0 )then
            userActions:cancelWaitForTileSelection();
            --print("wall build canceled item selected")
            eventRelay:dispatchItemSelectedEvents(map:getItem(tile.item), tile)
        else
            eventRelay:dispatchWrongTileSelected(event)
        end
        
    end
    
end


return UserActions;


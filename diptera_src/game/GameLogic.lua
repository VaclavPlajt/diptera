
-- macro (high-level) game logic
local GameLogic = {}


local millis = system.getTimer;

function GameLogic:new(game,gameGraphics, startMinions)
    local newGameLogic = {};
    
    -- set meta tables so lookups will work
    setmetatable(newGameLogic, self);
    self.__index = self;
    
    newGameLogic.game = game;
    newGameLogic.gameGraphics = gameGraphics;
    newGameLogic.mapGraphics = gameGraphics.mapGraphics;
    newGameLogic.minionController = game.minionController;
    newGameLogic.aIPlayerBehavior = game.aIPlayerBehavior;
    newGameLogic.humanPlayerAutomation = game.humanPlayerAutomation;
    newGameLogic.map = game.map;
    newGameLogic.startMinions = startMinions;
    newGameLogic.eventRelay = game.eventRelay;
    
    
    newGameLogic.aiPlayer = game.aiPlayer;
    newGameLogic.humanPlayer = game.humanPlayer;
    
    newGameLogic.pausesDuration = 0; -- time spend in puses
    newGameLogic.pauseStartTime = 0;
    
    -- treasures
    newGameLogic.treasureEffects = require("game.TreasureEffects");
    
    -- listen to keep buildings live cycles events
    newGameLogic.keepDestroyedListener = function(event) newGameLogic:onKeepDestroyed(event) end;
    Runtime:addEventListener("keepDestroyed", newGameLogic.keepDestroyedListener);
    
    newGameLogic.keepRegeneretedListener = function(event) newGameLogic:onKeepRegenerated(event) end;
    Runtime:addEventListener("keepRegenerated", newGameLogic.keepRegeneretedListener);
    
    newGameLogic.keepConvertedListener = function(event) newGameLogic:onKeepConverted(event) end;
    Runtime:addEventListener("keepConverted", newGameLogic.keepConvertedListener);
    
    -- listen to bombartment events
    newGameLogic.bomLandedListener = function(event) newGameLogic:doBonbardment(event) end;
    Runtime:addEventListener("bombLanded", newGameLogic.bomLandedListener);
    
    -- listen to treasure unlocks
    newGameLogic.treasureUnlockedList = function(event) newGameLogic:onTreasureUnlocked(event) end;
    Runtime:addEventListener("treasureUnlocked", newGameLogic.treasureUnlockedList);
    
    -- listen to material counts changes
    newGameLogic.matCoutListener = function(event) newGameLogic:updateMaterialCount(event) end;
    Runtime:addEventListener("infoevent", newGameLogic.matCoutListener);
    
    -- listen to new building created
    newGameLogic.newMapItemListener = function(event) newGameLogic:onNewMapItem(event) end;
    Runtime:addEventListener("buildingCreated", newGameLogic.newMapItemListener);
    
    
    --newGameLogic.state = "ready";
    return newGameLogic;
end


function GameLogic:start()
    
    -- add starting set of minions
    self.minionController:createStartMinions(self.startMinions);
    
    -- schedule regular task updates
    self.minionUpdatesTimer = timer.performWithDelay(300, function() self.minionController:updateTasks(); end, -1);
    
    -- scheduele regula AI player behavior update
    self.aiPlayerUpdatesTimer =  timer.performWithDelay(350, 
    function()
        local timeStamp = millis() - self.pausesDuration;
        self.aIPlayerBehavior:update(timeStamp);
        --self.humanPlayerAutomation:update(timeStamp); -- no longer needed, to be removed in future versions
    end, -1);
    
    -- recalculate human player controlled material
    self:updateMaterialCount();
    
    
    --[[
    timer.performWithDelay(3500, 
    function()
        self:onHumanPlayerLoss();
        --self:onHumanPlayerWin();
    end
    );
    ]]
    
    --self.state = "running";
end

function GameLogic:pause()
    
    if(self.minionUpdatesTimer) then
        timer.pause(self.minionUpdatesTimer);
    end;
    
    if(self.aiPlayerUpdatesTimer) then
        timer.pause(self.aiPlayerUpdatesTimer);
    end
    
    self.pauseStartTime = millis();
    
end

function GameLogic:resume()
    
    if(self.minionUpdatesTimer) then
        timer.resume(self.minionUpdatesTimer);
    end;
    
    if(self.aiPlayerUpdatesTimer) then
        timer.resume(self.aiPlayerUpdatesTimer);
    end
    
    self.pausesDuration = self.pausesDuration + (millis()-self.pauseStartTime);
    
end

function GameLogic:restart(newMap, newGameGraphics)
    
    -- cancel regular updates
    if(self.minionUpdatesTimer) then
        timer.cancel(self.minionUpdatesTimer);
        self.minionUpdatesTimer = nil;
        
        timer.cancel(self.aiPlayerUpdatesTimer);
        self.aiPlayerUpdatesTimer = nil;
    end
    
    self.map = newMap;
    self.mapGraphics = newGameGraphics.mapGraphics;
    self.pausesDuration = 0;
    
    -- log event to analytics
    self.game.context:analyticslogEvent("GameLogic-restart", {gameName=self.game.gameName});
    
end

function GameLogic:destroy()
    
    -- cancel regular updates
    if(self.minionUpdatesTimer) then
        timer.cancel(self.minionUpdatesTimer);
        self.minionUpdatesTimer = nil;
        
        timer.cancel(self.aiPlayerUpdatesTimer);
        self.aiPlayerUpdatesTimer = nil;
    end
    
    self.map = nil;
    self.mapGraphics = nil;
    
    
    -- remove all listeners
    Runtime:removeEventListener("keepDestroyed", self.keepDestroyedListener);
    Runtime:removeEventListener("keepRegenerated", self.keepRegeneretedListener);
    Runtime:removeEventListener("keepConverted", self.keepConvertedListener);
    Runtime:removeEventListener("bombLanded", self.bomLandedListener);
    Runtime:removeEventListener("treasureUnlocked", self.treasureUnlockedList);
    Runtime:removeEventListener("infoevent", self.matCoutListener);
    Runtime:removeEventListener("buildingCreated", self.newMapItemListener);
end

function GameLogic:onKeepConverted(event)
    
    local keep = event.keep;
    
    local map = self.map;
    local tile = map.tiles[keep.r][keep.u];
    local c = map.clusters[tile.cluster];
    
    if(c.isGoal) then
        self:onHumanPlayerWin();
        require("game.map.buildings.HomeKeep"):new(keep.r,keep.u,map);
    else
        -- create human player keep where the previous destroyed was standing
        require("game.map.buildings.Keep"):new(keep.r,keep.u, map);
        
    end
    
    -- add all inactive minions to human player
    local inactiveMinions =  c.inactiveMinions;
    for index, minion in pairs(inactiveMinions) do
        self.minionController:addMinion(minion);
        inactiveMinions[index] = nil;
    end
    
    self:setClusterOwner(tile.cluster, self.humanPlayer);
    
    -- play sound
    Runtime:dispatchEvent({name="soundrequest", type="playnammed", soundName="keep_convert"});--, x=x, y=y});  
    
end


function GameLogic:onKeepRegenerated(event)
    
    local keep = event.keep;
    
    local map = self.map;
    local tile = map.tiles[keep.r][keep.u];
    local cluster = map.clusters[tile.cluster];
    local goalKeep = false;
    
    if(cluster.isGoal) then goalKeep = true; end
    
    
    -- create enemy keep keep where the previous regenerated was standing
    require("game.map.buildings.EnemyKeep"):new(keep.r,keep.u, map, goalKeep);
    
    self:setClusterOwner(tile.cluster, self.aiPlayer);
    
    self.minionController:moveMinonsFromEnemyClusters();
    
    -- play sound
    Runtime:dispatchEvent({name="soundrequest", type="playnammed", soundName="keep_regen"});--, x=x, y=y});  
    
end

function GameLogic:onKeepDestroyed(event)
    local keep = event.keep;
    --print("GameLogic:onKeepDestroyed(event): " .. keep.typeName );
    
    if(keep.typeName=="HomeKeep") then
        self:onHumanPlayerLoss();
        return;
    end
    
    
    local map = self.map;
    local tile = map.tiles[keep.r][keep.u];
    local cluster = map.clusters[tile.cluster];
    local goalKeep = false;
    
    if(cluster.isGoal) then goalKeep = true; end
    
    -- create destoyed keep where the previous was standing
    require("game.map.buildings.DestroyedKeep"):new(keep.r,keep.u, map, goalKeep);
    
    self:changeClusterToUntakenState(tile.cluster);
    
    -- play sound
    Runtime:dispatchEvent({name="soundrequest", type="playnammed", soundName="keep_destroyed"});--, x=x, y=y});  
    
end

function GameLogic:changeClusterToUntakenState(clusterNum)
    local map = self.map;
    local cluster = map.clusters[clusterNum];
    
    
    -- remove from previous owner
    local oldOwner = map:getPlayerById(cluster.owner);
    if(oldOwner == nil) then return; end; -- cluster alredy in untaken state
    oldOwner:removeCluster(clusterNum);
    
    
    -- set owner to  -1
    cluster.owner  = -1;
    
    -- remove requests from all buildings
    for index, tileCoord in pairs(cluster.tiles) do
        local tile = map.tiles[tileCoord[1]][tileCoord[2]];
        
        if(tile.item and tile.item > 0) then
            local item = map:getItem(tile.item);
            
            if(item.typeName == "BuildingSite") then
                item:destroy();
            elseif(item.typeName == "Gun") then
                item:stopFiring();
            elseif(item.typeName == "Treasure") then
                item:cancelWorkRequest();
            elseif(item.typeName == "Material") then
                item:cancelBringHereRequest();
            elseif(oldOwner and item.typeName == "Material") then
                oldOwner:removeMaterial(item);
            else
                if(item.isBuilding) then
                    item:cancelAllRequests();
                end
            end
        end
    end
    
    
    
    -- notify map graphics
    self.mapGraphics:clusterChangedOwner(clusterNum);
    
    -- recalculate human player controlled material
    self:updateMaterialCount();
    
    -- notify event relay 
    self.eventRelay:clusterChangedOwner(clusterNum)
end


function GameLogic:setClusterOwner(clusterNum, newOwner)
    local map = self.map;
    local cluster = map.clusters[clusterNum];
    local isPlayer = not newOwner.isAI;
    
    -- remove from previous owner
    local oldOwner = map:getPlayerById(cluster.owner);
    if(oldOwner) then
        oldOwner:removeCluster(clusterNum);
    end
    
    -- add cluster to new player
    newOwner:addCluster(clusterNum);
    -- set owner to cluster
    cluster.owner  = newOwner.id;
    
    -- do per-tile stuff (remove requests from all buildings, destroy builduing sites..)
    for index, tileCoord in pairs(cluster.tiles) do
        local tile = map.tiles[tileCoord[1]][tileCoord[2]];
        
        if(tile.item and tile.item > 0) then
            local item = map:getItem(tile.item);
            
            if(item.isBuilding) then
                
                if(item.typeName == "BuildingSite") then
                    item:destroy();
                else
                    item:cancelAllRequests();
                end
                
                if(isPlayer and item.repairIfNeeded) then
                    item:repairIfNeeded();
                end
                
                
            else -- map items
                if(item.typeName == "Material") then
                    if(oldOwner) then
                        oldOwner:removeMaterial(item);
                    end
                    
                    if(isPlayer) then
                        newOwner:addMaterial(item);
                    end
                end
            end
        end
    end
    
    
    -- notify map graphics
    self.mapGraphics:clusterChangedOwner(clusterNum);
    
    -- recalculate human player controlled material
    self:updateMaterialCount();
    
    -- notify event relay 
    self.eventRelay:clusterChangedOwner(clusterNum)
    
end

--[[
function GameLogic:doBonbardment(event)
    --print("GameLogic:doBonbardment(event)");
    
    local cr,cu,areaSize = event.r, event.u, event.areaSize;
    local damage = event.damage;
    local dCoord = areaSize-1;
    local map = self.map;
    local size = map.size;
    
    local sr = cr - dCoord;
    if(sr < 1 )then
        sr = 1;
    end
    
    local su = cu - dCoord;
    if(su < 1) then
        su = 1;
    end
    
    
    local gr = cr + dCoord;
    if(gr>size) then
        gr = size;
    end
    
    local gu = cu + dCoord;
    if(gu>size) then
        gu =  size;
    end
    
    local tiles = map.tiles;
    for r = sr, gr do
        for u = su, gu do
            local tile =tiles[r][u];
            
            if(tile.item >0) then
                local item = map:getItem(tile.item);          
                --print(item.typeName .. " hit by bombardment");
                if(item.hit)then
                    item:hit(damage);
                end
                
            end
        end
    end
end
]]

function GameLogic:onTreasureUnlocked(event)
    local treasure = event.treasure;
    local treasureName = treasure.treasureName;
    --local params =  treasure.treasureParams;
    --print("Trasure unlocked: " .. treasureName );
    
    
    if(self.treasureEffects[treasureName])then
        self.treasureEffects[treasureName](self.game, treasure, treasure.r, treasure.u);
        
    else
        print("Warning: Treasure effect for name: " .. tostring(treasureName) .. " not found!!  " );
    end
    
end

function GameLogic:onHumanPlayerLoss()
    --print("Loss loss loss");
    
    self.game:pause();
    
    -- show win loss window
    require("ui.win.WinLossPane"):new(
    self.gameGraphics.uiLayer,
    function() self.game:restartGame() end,
    function() Runtime:dispatchEvent{name="actionSelected", action="closeGame", params = nil}; end,
    false, self.game.context);
    
    -- play sound
    Runtime:dispatchEvent({name="soundrequest", type="playnammed", soundName="loss"});
    
    -- log event to analytics
    self.game.context:analyticslogEvent("GameLogic-onHumanPlayerLoss", {gameName=self.game.gameName});
    
end

function GameLogic:onHumanPlayerWin()
    --print("Win Win Win");
    
    self.game:pause();
    
    -- show win loss window
    require("ui.win.WinLossPane"):new(
    self.gameGraphics.uiLayer,
    function() self.game:restartGame() end,
    function() Runtime:dispatchEvent{name="actionSelected", action="closeGame", params = nil}; end,
    true, self.game.context);
    
    -- play sound
    Runtime:dispatchEvent({name="soundrequest", type="playnammed", soundName="win"});
    
    -- persist: level cleared
    local ws = require("io.worldState");
    ws.levelCleared(self.game.gameName);
    
    -- log event to analytics
    self.game.context:analyticslogEvent("GameLogic-onHumanPlayerWin", {gameName=self.game.gameName});
    
end


function GameLogic:onNewMapItem(event)
    local b = event.building;
    
    --print("GameLogic:onNewMapItem(event)");
    
    if(b and b.typeName == "Material") then
        
        local owner = self.map:getTileOwner(b.r, b.u);
        if(not owner.isAI)then
            owner:addMaterial(b);
            event.info="matAdded";
            self:updateMaterialCount(event);
        end
    end
    
end

function GameLogic:updateMaterialCount(event)
    if(event == nil or event.info == "matTaken" or event.info=="matAdded") then
        local count  = self.humanPlayer:countMaterial();
        Runtime:dispatchEvent{name="infoevent", info="matCount", count=count};
    end
end

return GameLogic;


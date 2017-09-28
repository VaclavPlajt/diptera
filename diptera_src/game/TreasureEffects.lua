

local TreasureEffects = {}

--[[
    treasures = {
        {name = "movementBoost",  params = {ratio = 1.1}},
        {name = "wallBoost", params = {ratio = 1.5}},
        {name = "workBoost", params = {ratio = 0.9}},
        {name = "newMinions", params = {amount = 1},
    },
]]

local function forEachMinionInGame(game, workFun)

    -- do work for all minions in minion controller
    local minionController =  game.minionController;
    local minions = minionController.minions;
    
    for i=1, #minions do
        workFun(minions[i]);
    end
    
    -- do work for inprisoned minions on map
    local clusters = game.map.clusters;
    
    for i=1, #clusters do
        local c = clusters[i];
        if(c.inactiveMinions and #c.inactiveMinions > 0) then
            minions = c.inactiveMinions;
            for j=1, #minions do
                workFun(minions[j]);
            end
        end
    end
end


function TreasureEffects.movementBoost(game, treasure,r,u)
    
    local multiplier = treasure.treasureParams.multiplier;
    local gameConst = game.gameConst;
    
    -- change movement speed for newly creted minions
    gameConst.minionMovementSpeed = gameConst.minionMovementSpeed * multiplier; 
    
    -- change movement speed for each minion in game
    forEachMinionInGame(game, function(minion) minion.movementSpeed = minion.movementSpeed *multiplier; end)
    
    -- create treasure marking unit
    require("game.unit.Bonus"):new(r,u,game.map, treasure, game.context)
end

function TreasureEffects.wallBoost(game, treasure, r,u)
    local multiplier = treasure.treasureParams.multiplier;
    
    -- change toughness for every new wall build
    local wallDef = game.gameConst.Wall;
    local newToughness = math.ceil(wallDef.toughness * multiplier);
    wallDef.toughness = newToughness;
    
    
    game.map:forEachItemOfType("Wall",
        function(wall)
            --local damage = wall.toughness - wall.fitness;
            wall.toughness = newToughness; 
            wall.repairRequestLimit = math.ceil(newToughness*wallDef.repairRequestLimitMultip);
            wall.fitness = newToughness;
            wall:cancelRepair();
            --[[
            if(wall.fitness <= wall.repairRequestLimit) then -- send repir request if needed
                wall:requestRepair();
            end]]
            wall:updateGraphics();
            --print("wall boosted to toughness:" .. newToughness);
        end );
    
    -- create treasure marking unit
    require("game.unit.Bonus"):new(r,u,game.map, treasure, game.context)
end

function TreasureEffects.workBoost(game, treasure, r,u)
    -- change work delay for every future work unit 
    local workHandler = game.minionController.workHandler;
    workHandler.workUnitDelay = workHandler.workUnitDelay * treasure.treasureParams.multiplier;
    
    local repairHandler = game.minionController.repairHandler;
    repairHandler.repairUnitDelay = repairHandler.repairUnitDelay * treasure.treasureParams.multiplier;
    
    -- create treasure marking unit
    require("game.unit.Bonus"):new(r,u,game.map, treasure, game.context)
end

function TreasureEffects.gunBoost(game, treasure, r,u)
    
    local multiplier = treasure.treasureParams.multiplier;
    
    -- change toughness for every new wall build
    local gunDef = game.gameConst.Gun;
    local newMisilesDamage = math.ceil(gunDef.misilesDamage * multiplier);
    gunDef.misilesDamage = newMisilesDamage;
    
    
    game.map:forEachItemOfType("Gun",
        function(gun)
            --local damage = wall.toughness - wall.fitness;
            gun.misilesDamage = newMisilesDamage; 
            --gun.repairRequestLimit = math.ceil(newMisilesDamage*gunDef.repairRequestLimitMultip);
            --gun.fitness = newMisilesDamage;
            --gun:cancelRepair();
            --[[
            if(wall.fitness <= wall.repairRequestLimit) then -- send repir request if needed
                wall:requestRepair();
            end]]
            --gun:updateGraphics();
            --print("wall boosted to toughness:" .. newToughness);
        end );
    
    -- create treasure marking unit
    require("game.unit.Bonus"):new(r,u,game.map, treasure, game.context)
    
    
end

function TreasureEffects.newMinions(game, treasure, r,u)
    
    local amount = treasure.treasureParams.amount;
    local map = game.map;
    local minionController =  game.minionController;
    
    for i=1, amount do
        local minion = require("game.unit.Minion"):new(r,u,map.isoGrid);
        minionController:addMinion(minion, true);
    end
    
    -- play sound
    Runtime:dispatchEvent({name="soundrequest", type="playnammed", soundName="minion_free"});
    
    -- show info graphics
    local x,y = game.map.isoGrid:isoToCart(r,u);
    local layer = game.gameGraphics.mapGraphics.aboveMapLayer;
    -- new(x,y,layer,context, count, icon, text)
    local inGamePanel =  require("ui.info.InGameInfoPanel"):new(x+128,y-64,layer,game.context, "+" .. tostring(amount), "img/minion/m_down.png", nil,2);
    inGamePanel:fadeOut();
    
end

function TreasureEffects.newMaterial(game, treasure, r,u)
    
    local amount = treasure.treasureParams.amount;
    local map = game.map;

    require("game.map.items.Material"):new(r,u,amount,map);    
    
    -- play sound
    Runtime:dispatchEvent({name="soundrequest", type="playnammed", soundName="put"});
    
    -- show info graphics
    local x,y = game.map.isoGrid:isoToCart(r,u);
    local layer = game.gameGraphics.mapGraphics.aboveMapLayer;
    -- new(x,y,layer,context, count, icon, text)
    local inGamePanel =  require("ui.info.InGameInfoPanel"):new(x+128,y-64,layer,game.context, "+" .. tostring(amount), "img/material/mat_100.png", nil);
    inGamePanel:fadeOut();
    
end


function TreasureEffects.empty(game, treasure, r,u)
    -- do nothing, but show it :)
    
    -- create treasure marking unit
    require("game.unit.Bonus"):new(r,u,game.map, treasure, game.context)
end

return TreasureEffects;


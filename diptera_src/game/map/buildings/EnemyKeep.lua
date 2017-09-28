
-- building used to attack enemy teritories
local EnemyKeep = {};

setmetatable(EnemyKeep, require("game.map.buildings.Building"))
EnemyKeep.__index = EnemyKeep

EnemyKeep.infoProperties = {"powerCategory"}; -- properties to show in infoPanel
EnemyKeep.iconDir = "img/keep/"
EnemyKeep.icon="cat1_covered.png";

local rnd = math.random;

function EnemyKeep:new(r,u,map,mainEnemyKeep)
    --local gameConst = require("game.gameConst");
    local clusterNum = map.tiles[r][u].cluster;
    local powerProperties = map.clusters[clusterNum].powerProperties;
    local toughness = powerProperties.keepToughness;
    local itemType = "EnemyKeep";
    
    
    --local toughness = gameConst.EnemyKeep.toughness;
    local newEnemyKeep = require("game.map.buildings.Building"):new(itemType,r, u, map,toughness);
    
    
    if(mainEnemyKeep) then
        newEnemyKeep.mainEnemyKeep = true;
    end
    
    -- set meta tables so lookups will work
    setmetatable(newEnemyKeep, self);
    self.__index = self;
    
    
    newEnemyKeep.lastFiredTime = -1;
    --newEnemyKeep.active = false;
    newEnemyKeep.fireTargetClusters ={};
    newEnemyKeep.firePeriod = powerProperties.firePeriod;
    newEnemyKeep.misilesDamage = powerProperties.damage;
    newEnemyKeep.powerCategory = powerProperties.powerCategory;
    
    
    
    -- let others know
    newEnemyKeep:dispatchBuildingCreatedEvent()
    
    return newEnemyKeep;
end


function EnemyKeep:initGraphics(x,y,layer, img, mapDebugLayer)
    self.layer = layer;
    
    local imgName;
    if(self.mainEnemyKeep) then
        imgName = "home_covered.png";
    else
        imgName = "cat" .. self.powerCategory .. "_covered.png";
    end
    
    self.icon = imgName;
    self.dispObj = img:newTileImg{w=128, h=128, dir= "keep", name=imgName, cx=x, cy = y}
    self:insertToCalcIndex(self.layer,self.dispObj);
    
    --self.dot = display.newCircle(layer, x, y, 5);
    --self.dot:setFillColor(1,0,0,1);
    --self.dot.isVisible = self.active;
    
    if(mapDebugLayer) then
        self.label = display.newText("" .. self.fitness, x, y, native.systemFont, 14 )
        mapDebugLayer:insert(self.label);
    end
    
    --myText:setFillColor(0.9,0.3,0.2,1);
    
end


function EnemyKeep:updateGraphics()
    if(self.label) then
        self.label.text = tostring(self.fitness);
    end
    --self.dot.isVisible = self.active;
end


--[[
-- activates or deactivates keep
-- keep is activated whned on cluster with human player in neighborhood
-- and deactivated otherwise
function EnemyKeep:checkActivation()
    local map = self.map;
    local clusterNum =  map.tiles[self.r][self.u].cluster;
    local cluster = map.clusters[clusterNum];
    local myOwner = cluster.owner;
    local neighbours = cluster.neighbors;
    local prevActiovation = self.active;
    
    self.active = false;
    self.fireTargetClusters = {};
    
    for neighClustrNum, t in pairs(neighbours) do
        
        local neighCluster = map.clusters[neighClustrNum];
        
        if(neighCluster.owner ~= myOwner) then
            self.active = true;
            -- add neighbour to list of potential fire targets
            self.fireTargetClusters[#self.fireTargetClusters + 1] = neighClustrNum;
            
            if(prevActiovation == false) then self.lastFiredTime = -1; end
        end
        
    end
    
    
end
]]

function EnemyKeep:updateFireState(timeStamp, aIPlayerBehavior)
    
    --if(self.activated == false) then return; end;
    
    --print("updating fire state, timestamp: " .. tostring(timeStamp))
    
    if(self.lastFiredTime <= 0) then
        self.lastFiredTime = timeStamp;
        return;
    end
    
    
    if(timeStamp - self.lastFiredTime  > self.firePeriod) then
        -- time to fire
        self:fire(timeStamp, aIPlayerBehavior);
    end
    
end

function EnemyKeep:setTargetClusters(targetClusters)
     self.fireTargetClusters = targetClusters;
end

function EnemyKeep:fire(timeStamp, aIPlayerBehavior)
    
    
    self.lastFiredTime = timeStamp;
    
    if(self.fireTargetClusters== nil or #self.fireTargetClusters <= 0) then
        print("Warning: EnemyKeep:fire() no target clusters to fire on !!");
        return;
    end
    
    -- determine target item
    local map = self.map;
    local targetClusterNum = self.fireTargetClusters[ rnd(1,#self.fireTargetClusters)];
    local targetKeepCoord = map.clusters[targetClusterNum].meanTile;
    local targetItem;-- = map:getItem(map.tiles[targetKeepCoord[1]][targetKeepCoord[2]].item); -- cluster keep
    
    -- find misile path to target
    local path, alternative, newItem  = aIPlayerBehavior:findMissilePath(self.r,self.u, targetKeepCoord[1], targetKeepCoord[2]);
    
    -- path to intended goal is blocked by map item, so target the item
    if(alternative) then
        targetItem = newItem;
    else
        -- get clusters keep
        targetItem = map:getItem(map.tiles[targetKeepCoord[1]][targetKeepCoord[2]].item); -- cluster keep
    end
    
    if(path and targetItem) then
        --print("fire!!");
        local onHit = nil;
        
        if(targetItem.hit) then
            -- mozna by to melo byt primo v misile ???
            onHit = function() targetItem:hit(self.misilesDamage, "EnemyMissile"); end
        end
        
        aIPlayerBehavior:fireMissile(path, self.misilesDamage,  onHit);
    else
        print("EnemyKeep: target not found, no missile will be fired");
    end
    
end

function EnemyKeep:destroy()
    if(self.destroyed) then return; end;
    
    
    self.destroyed = true;
    
    self.map:removeItem(self);
    --print("Warning default implementation of Building:destroyed() -  does nothing");
    self.dispObj:removeSelf();
    self.dispObj = nil;
    if(self.label) then self.label:removeSelf(); self.label = nil; end
    --self.dot:removeSelf();
    --self.dot = nil;
    
    if(self.lastHitEmmiter) then
        self.lastHitEmmiter:removeSelf();
        self.lastHitEmmiter = nil;
    end
    
    -- main game evwnt, let others know
    Runtime:dispatchEvent{name="keepDestroyed", keep = self};
       
    
end

return EnemyKeep;










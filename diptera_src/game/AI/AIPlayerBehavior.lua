
local AIPlayerBehavior = {}

local abs = math.abs;
local max = math.max;

function AIPlayerBehavior:new(map, pathFinder, aiPlayer, humanPlayer)
    local gameConst = require("game.gameConst");
    local AIParams = gameConst.AIParams;
    local newAIPlayerBehavior = {};
    
    -- set meta tables so lookups will work
    setmetatable(newAIPlayerBehavior, self);
    self.__index = self;
    
    newAIPlayerBehavior.humanPlayer = humanPlayer;
    newAIPlayerBehavior.aiPlayer = aiPlayer;
    --newAIPlayerBehavior.gameState = gameState;
    newAIPlayerBehavior.pathFinder = pathFinder;
    newAIPlayerBehavior.map = map;
    --newAIPlayerBehavior.startTimeStamp = -1;
    --newAIPlayerBehavior.aiPlayerStartDelay = aiPlayerStartDelay or 0;
    
    
    --[[
    -- bombarding parameters
    newAIPlayerBehavior.bombardingPeriod =  AIParams.startBombardingPeriod;-- in ms
    newAIPlayerBehavior.bombardingPeriodShortening =   AIParams.bombardingPeriodShortening;-- dimension less
    newAIPlayerBehavior.minBonbardmentPeriod = AIParams.minBonbardmentPeriod;
    newAIPlayerBehavior.bombardingDamage  =  AIParams.startBombardingDamage;
    newAIPlayerBehavior.bombardingDamageGrowt =   AIParams.bombardingDamageGrowt;
    newAIPlayerBehavior.maxBombardingDamage = AIParams.maxBombardingDamage;
    newAIPlayerBehavior.bombardingAreaSize =     AIParams.bombardingAreaSize; 
    newAIPlayerBehavior.lastBombardmentTime = -1;
    newAIPlayerBehavior.bombardment = 0;
    newAIPlayerBehavior.lastBraodcastedBombValue = 0;
    ]]
    
    --newAIPlayerBehavior:checkClustersState();
    return newAIPlayerBehavior;
end

function AIPlayerBehavior:restart(newMap)
    self.map = newMap;
    --self.startTimeStamp = -1;
    --[[
    -- reset bombarding
    self.lastBombardmentTime = -1;
    self.bombardment = 0;
    self.lastBraodcastedBombValue = 0;
    ]]
end


function AIPlayerBehavior:destroy()
    self.map = nil;
end

function AIPlayerBehavior:checkClustersState()
    local clusters = self.map.clusters;
    
    for clusterNum, val in pairs(self.aiPlayer.ownedClusters) do
        local c = clusters[clusterNum];
        
        self:checkClusterState(c, clusterNum);
    end
    
end


function AIPlayerBehavior:checkClusterState(cluster, clusterNum)
    
    self.map:checkEnemyClusterActivation(clusterNum);
    
    if(cluster.active) then
        local keep = self.map:getClusterKeep(clusterNum);
        --[[
        if(keep.typeName ~= "EnemyKeep") then
            print("Warning: keep in enemy sluster is not enemy keep!! BUG ???");
            return;
        end
        ]]
        keep:setTargetClusters(cluster.adjecentHumanClusters);
    end
    
end


function AIPlayerBehavior:update(timeStamp)
    --local timeStamp = system.getTimer();
    --[[
    if(self.startTimeStamp < 0 )then
        self.startTimeStamp = timeStamp;
    end
    ]]
    
    if(self.aiPlayer.ownedClustersChanged or self.humanPlayer.ownedClustersChanged)then
        self.aiPlayer.ownedClustersChanged = false;
        self:checkClustersState();
    end
    
    --if(timeStamp - self.startTimeStamp >= self.aiPlayerStartDelay) then
    
    --self:updateKeepsFire(timeStamp);
    self:updateActiveClusters(timeStamp);
    self:updateDestroyedKeepsRegeneration(timeStamp);
    --self:updateBombarding(timeStamp);
    --end
end

function AIPlayerBehavior:updateActiveClusters(timeStamp)
    local map =  self.map;
    --local myKeeps = map:getAllItemsOfType("EnemyKeep");
    
    for clusterNum, val in pairs(self.aiPlayer.ownedClusters) do
        local cluster = map.clusters[clusterNum];
        
        if(cluster.active) then
            -- update firing keeps
            local keep = map:getClusterKeep(clusterNum);
            if(keep.typeName == "EnemyKeep") then
                keep:updateFireState(timeStamp, self);
            else
                print("Warning: active cluster dos not containd EnemyKeep, contains:" .. keep.typeName);
            end;
        end
    end
    
end

--[[
function AIPlayerBehavior:updateKeepsFire(timeStamp)
    
    local map =  self.gameState.map;
    local myKeeps = map:getAllItemsOfType("EnemyKeep");
    
    if(myKeeps == nil)then return end;
    
    for index,keep in pairs(myKeeps) do
        if(keep.active) then
            keep:updateFireState(timeStamp, self);
        end
    end
    
end
]]

function AIPlayerBehavior:updateDestroyedKeepsRegeneration(timeStamp)
    local map =  self.map;
    local myDestroyedKeeps = map:getAllItemsOfType("DestroyedKeep");
    
    if(myDestroyedKeeps==nil) then return; end;
    
    for index,dkeep in pairs(myDestroyedKeeps) do
        if(not dkeep.destroyed) then
            dkeep:updateRegenerationState(timeStamp, self);
        end
    end
    
end

function AIPlayerBehavior:fireMissile(path, misilesDamage, onTargetHit)
    local isoGrid = self.map.isoGrid;
    local r,u = path[1][1], path[1][2];
    
    -- create missile and sent it along path to hit target
    local  missile =  require("game.unit.EnemyMissile"):new(r,u,path,isoGrid, misilesDamage, onTargetHit);
    
    missile:move();
    
end

--- paths

-- misiles can fly over map item with exception of walls and materials
function AIPlayerBehavior:canMissileAccessTile(r,u)
    local map = self.map;
    local size = map.size;
    
    if(u > 0 and u <= size and r >0 and r <= size) then 
        -- get current shot clusters
        --local currentPlayerId = self.player.id;
        local tile = map.tiles[r][u];
        local tileClusterNum = tile.cluster;
        local blockingItem = false;
        local item;
        
        if(tile.item > 0) then
            item = map:getItem(tile.item);
            if(item.typeName == "Wall") then -- or item.typeName == "Material") then
                blockingItem = true; -- blocking item
            end
        end
        
        -- missile can acces the tile when it is in goal or source cluster and there is no item on tile
        if(blockingItem == false) then
            if (tileClusterNum== self.pathSourceClusterNum or tileClusterNum == self.pathGoalClusterNum) then
                return true;
            end
        else
            --if its a first block and blocking item is a wall remember blocking item coordinate
            if(self.lastBlockR == -1 and item.typeName == "Wall") then
                self.lastBlockR = r;
                self.lastBlockU = u;
            end
            return false;
        end
        
    end
    
    return false;
end 

local function isNextToGoal(gr, gu, cNode)
    local cr, cu = cNode[1], cNode[2];
    
    local dist = max(abs(cr-gr),abs(cu-gu));
    
    if(dist <= 1) then 
        return true;
    end
    
    return false;
end

-- findMissilePath(sr,su, gr, gu)
-- tiles on coordintes sr, su and gr, gu have to be in adjecent clusters !  
-- returns path, alternative, newItem
--- path -  missile path to intended target of to item blocking path to target or nil if cannot be found
--- alternative - true if path to intended target is blocked and returned path is path to blocking item
function AIPlayerBehavior:findMissilePath(sr,su, gr, gu)
    --local r,u  = minion:getIsoCoord();
    -- determine source and goal clusters
    local tiles = self.map.tiles;
    self.pathSourceClusterNum = tiles[sr][su].cluster;
    self.pathGoalClusterNum = tiles[gr][gu].cluster;
    self.lastBlockR = -1;
    self.lastBlockU = -1;
    
    local path = self.pathFinder:findPath(sr,su,gr,gu,
    function(r,u) return self:canMissileAccessTile(r,u) end,
    nil, false);
    
    
    
    if(path == nil and self.lastBlockR > 0 and self.lastBlockU >0) then
        --print("missile path blocked at:" .. self.lastBlockR .. ", " .. self.lastBlockU );
        local newTargetItem = self.map:getItem( self.map.tiles[self.lastBlockR][self.lastBlockU].item);
        
        if(self.lastBlockR > 0 and self.lastBlockU > 0) then
            local blockR, blockU = self.lastBlockR,self.lastBlockU;
            path = self.pathFinder:findPath(sr,su,
            self.lastBlockR,self.lastBlockU,
            function(r,u) return self:canMissileAccessTile(r,u) end,
            function(cNode) return isNextToGoal(blockR, blockU,cNode)end,
            false);
            
            if(path) then -- add last path segment
                -- following line may cause inacurate selection of missile direction image
                -- but I will keep it this way since missiles moves fast and right solution
                -- seems to be too complicated
                path[#path+1] = {self.lastBlockR, self.lastBlockU, 0,0,0,0,0};
            end
        end
        
        
        return path, true, newTargetItem;
    end
    
    return path, false, nil;
end

--[[
function AIPlayerBehavior:updateBombarding(timeStamp)

    
    if(self.lastBombardmentTime < 0 ) then -- first run
        self.lastBombardmentTime = timeStamp;
        self.bombardment = 0;
        return;
    end
    
    self.bombardment = (timeStamp-self.lastBombardmentTime)/self.bombardingPeriod;
    
    if(  abs(self.lastBraodcastedBombValue-self.bombardment) >= 0.02 ) then
        Runtime:dispatchEvent{name = "bombardmentUpdate", bombardment= self.bombardment};
    end
    
    if(self.bombardment >= 1) then
        self:onBombardment(timeStamp);
    end
    
end

function AIPlayerBehavior:onBombardment(timeStamp)
    local floor = math.floor;
    --print("BOOOOOOOOOOOOM, period:" .. self.bombardingPeriod .. ", damage:" .. floor(self.bombardingDamage));
    
    local clusterNum = self.humanPlayer:getRandomOwnedClusterNumber();
    local cluster = self.map.clusters[clusterNum];
    local tile = cluster.tiles[math.random(1,#cluster.tiles)];
    
    Runtime:dispatchEvent{name = "bombLanded",
                            r= tile[1], u=tile[2],
                            areaSize = self.bombardingAreaSize,
                            damage = floor(self.bombardingDamage)};
           
    
    self.bombardingPeriod = floor(self.bombardingPeriod * self.bombardingPeriodShortening);-- in ms
    
    if(self.bombardingPeriod < self.minBonbardmentPeriod) then
        self.bombardingPeriod = self.minBonbardmentPeriod;
    end
    
    
    self.bombardingDamage  =  self.bombardingDamage * self.bombardingDamageGrowt;
    if(self.bombardingDamage > self.maxBombardingDamage) then
        self.bombardingDamage = self.maxBombardingDamage;
    end
    
    self.lastBombardmentTime = timeStamp;
    self.bombardment = 0;
    --newAIPlayerBehavior.bombardingAreaSize =     AIParams.bombardingAreaSize; 
    --newAIPlayerBehavior.lastBombartmentTime = -1;
    --newAIPlayerBehavior.bombartment = 0;
    
end
]]

return AIPlayerBehavior;


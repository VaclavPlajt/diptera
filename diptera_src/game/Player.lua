
local Player = {}

function Player:new(id, AI)
    
    local newPlayer = {};
    
    -- set meta tables so lookups will work
    setmetatable(newPlayer, self)
    self.__index = self;
    
    
    newPlayer.id = id;
    newPlayer.homeCluster = nil; -- first home cluster of human player
    newPlayer.ownedClusters = {};
    newPlayer.ownedClustersCount = 0;
    newPlayer.ownedClustersChanged = false;
    newPlayer.isAI = AI;
    newPlayer.controllerMaterials = {};
    
    return newPlayer;
    
end

function Player:clearState()
    self.homeCluster = nil;
    self.ownedClusters = {};
    self.ownedClustersCount = 0;
    self.ownedClustersChanged = false;
    self.controllerMaterials = {};
end

function Player:addCluster(clusterNum)
    self.ownedClusters[clusterNum] = true;
    self.ownedClustersCount = self.ownedClustersCount+1;
    self.ownedClustersChanged= true;
end

function Player:removeCluster(clusterNum)
    self.ownedClusters[clusterNum] = nil;
    self.ownedClustersCount = self.ownedClustersCount-1;
    self.ownedClustersChanged = true;
end


function Player:addMaterial(materialItem)
    self.controllerMaterials[materialItem] = materialItem;
    
end

function Player:removeMaterial(materialItem)
    self.controllerMaterials[materialItem] = nil;
end

function Player:countMaterial()
    
    local sum = 0;
    for key,material in pairs(self.controllerMaterials) do
        if(material.destroyed) then
            self.controllerMaterials[material] = nil;
        else
            sum = sum + material.amount;
        end
    end
    --print("materaial count:" .. sum );
    return sum;
end

function Player:getRandomOwnedClusterNumber()
    local list = self.ownedClusters;
    local n = math.random(1, self.ownedClustersCount);
    local lastK;
    local i = 0;
    
    for k,v in pairs(list) do
        
        if(v) then
            i = i+1;
            lastK = k;
            if(i == n) then
                return k;
            end
        end
    end
    
    if(lastK) then
        return lastK;
    end
    
    return nil;
end


return Player;
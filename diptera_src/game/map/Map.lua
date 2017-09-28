local Map = {}



function Map:new(params, isoGrid, aiPlayer, humanPlayer)
    
    local size = params.size;
    
    
    local newMap = {size=size, isoGrid = isoGrid, distFun=require("math.geometry").manhattanDist};
    
    -- set meta tables so lookups will work
    setmetatable(newMap, self);
    self.__index = self;
    
    -- players
    newMap.aiPlayer = aiPlayer;
    newMap.humanPlayer = humanPlayer;
    
    
    -- prealocate tables for tiles
    local tiles = {};
    for i = 1, size do
        local row = {}
        tiles[i] = row;
        for j= 1, size do
            row[j] = {item=0, cluster=nil, renderIndex = -1};
        end
    end
    
    newMap.tiles = tiles;
    newMap.maxRenderIndex = size*size;
    newMap.usedRenderIndexes = {};
    
    -- prealocate tables for edges
    local rightEdges = {};
    local upEdges = {};
    
    for i=1, size*(size+1) do
        rightEdges[i] = {};
        upEdges[i] = {};
    end
    
    newMap.rightEdges =rightEdges;
    newMap.upEdges = upEdges;
    
    -- prealocate memory for clusters
    newMap.clusters = {}
    local numOfclusters = params.numOfClusters;
    for i=1, numOfclusters do
        newMap.clusters[i] = {
            center=nil,size=nil,tiles={},meanTile=nil,owner=nil,
            borders={}, neighbors={},active=false, adjecentHumanClusters = {},
            inactiveMinions = {}, powerProperties ={}, shapeVertices = nil,
        };
    end
    
    -- add array for items on map (eg. buldings or other)
    newMap.items = {};
    newMap.itemsById = {};
    newMap.lastItemId = 0;
    
    -- queue user for item search queries
    newMap.itemsSearchQueue = require("datastructures.BinaryHeap"):new();
    
    -- determine tiles rendering order
    local counter = 0;
    isoGrid:traverseTilesInRenderingOrder(function(right, up, x, y)
        counter = counter +1;
        local tile = newMap.tiles[right][up];
        tile.renderIndex = counter;
    end);
    
    return newMap;
    
end

-- returns rendering index (position in map items corona group) for given item
function Map:getRenderIndex(item)
    local ri = self.tiles[item.r][item.u].renderIndex;
    
    local list = self.usedRenderIndexes;
    -- search in used indexes for closest smaller render index
    -- if array is empty
    if (#list <= 0) then
        list[1] = ri;
        return 1;
    end
    
    local imid;
    local imin = 1;
    local imax = #list;
    local floor = math.floor;
    
    while(imax >= imin) do
        -- calculate midpoint to cut set in half
        imid = floor((imin+imax)*0.5);
        
        if(list[imid] == ri) then
            -- key found at index imid
            --print("Warning Map:getRenderIndex(item): renderIndex alrady in use!")
            return imid; 
            
            -- determine which subarray to search
        elseif(list[imid] < ri) then
            -- change min index to search upper subarray
            imin = imid + 1;
        else         
            -- change max index to search lower subarray
            imax = imid - 1;
        end
    end
    
    -- render index was not found
    local index = math.max(imin,imax);
    table.insert(list, index, ri);
    
    return index;
    
end

-- removes item render index from used indexes list
function Map:removeRenderIndex(tile)
    --local ri = self.tiles[item.r][item.u].renderIndex;
    local ri = tile.renderIndex;
    
    
    local list = self.usedRenderIndexes;
    -- search in used indexes for closest smaller render index
    
    
    local imid;
    local imin = 1;
    local imax = #list;
    local floor = math.floor;
    
    while(imax >= imin) do
        -- calculate midpoint to cut set in half
        imid = floor((imin+imax)*0.5);
        
        if(list[imid] == ri) then
            -- key found at index imid
            table.remove(list, imid);
            return;
            -- determine which subarray to search
        elseif(list[imid] < ri) then
            -- change min index to search upper subarray
            imin = imid + 1;
        else         
            -- change max index to search lower subarray
            imax = imid - 1;
        end
    end
    
    -- render index was not found
   print("Warning Map: Render index of given item was not used")
    
end

-- adds item to map
-- returns items id
function Map:addItem(item)
    local id = self.lastItemId + 1;
    local itemType = item.typeName;
    local tile = self.tiles[item.r][item.u];
    
    
    if(tile.item > 0)then
        print("Warning adding item on tile where item elready exists!!")
    end
    
    tile.item = id;
    
    if(self.items[itemType] == nil) then self.items[itemType]={} end;
    
    self.items[itemType][id] = item;
    self.itemsById[id]  = item;
    
    self.lastItemId = id;
    return id;
end


function Map:getAllItemsOfType(itemType)
    return self.items[itemType];
end

function Map:forEachItemOfType(itemType, callback)
    local items = self.items[itemType];
    
    if(not items) then return; end;
    
    for id,wall in pairs(items) do
        callback(wall);
    end
    
end

function Map:getItem(id)
    
    --[[
    -- we don't know which building type is this, so we have to search through all types... :(
    for itemType,set in pairs(self.items) do
        if(set[id]) then
            return set[id];
        end
    end
    
    return nil;
    ]]
    return self.itemsById[id];
    
end

-- remove item from map
function Map:removeItem(item)
    local id = item.id;
    local itemType = item.typeName;
    local tile = self.tiles[item.r][item.u];
    
    self:removeRenderIndex(tile)
    tile.item = 0;
    self.items[itemType][id] = nil;
    self.itemsById[id] = nil;
        
end

-- find n-th closest item in territory
-- usually n is 1 (the colosest item), but since it can be inaccessibe we need to find next ones
-- the serch is done on neutral and human players teritories
function Map:findnNthClosestItem(itemType, r,u, n)
    local tiles = self.tiles;
    local clusters = self.clusters;
    local distFun = self.distFun;
    local cluster = clusters[tiles[r][u].cluster];
    local enemyId = self.aiPlayer.id;
    local distQueue = self.itemsSearchQueue;
    distQueue:clear();
    
    local itemsList = self.items[itemType];
    
    local minDist = 2*self.size;
    local itemOwner, dist, closestItem;
    
    for id, item in pairs(itemsList) do
        
        itemOwner = clusters[tiles[item.r][item.u].cluster].owner;
        
        if(itemOwner ~= enemyId ) then
            dist = distFun(r,u,item.r,item.u);
            
            distQueue:insert(dist, item)
            --[[
            if(dist< minDist) then
                minDist = dist;
                closestItem = item;
            end 
            ]]
        end    
    end
    
    for i = 1, n do
        minDist, closestItem  = distQueue:delMin();
    end
    
    
    return closestItem;
    
end


-- activates or deactivates cluster
-- ckuster is activated whned are human player owned clusters in neighborhood
-- and deactivated otherwise
-- returns true when activatin state changed, fale otherwise
function Map:checkEnemyClusterActivation(clusterNum)
    --local map = self.map;
    --local clusterNum =  self.tiles[self.r][self.u].cluster;
    local cluster = self.clusters[clusterNum];
    local myOwner = cluster.owner;
    local neighbours = cluster.neighbors;
    local prevActiovation = cluster.active;
    
    cluster.active = false;
    local adjecentHumanClusters = {};
    
    for neighClustrNum, t in pairs(neighbours) do
        
        local neighCluster = self.clusters[neighClustrNum];
        
        if(neighCluster.owner > 0  and neighCluster.owner ~= myOwner) then
            cluster.active = true;
            -- add neighbour to list of potential fire targets
            adjecentHumanClusters[#adjecentHumanClusters + 1] = neighClustrNum;
            
            --if(prevActiovation == false) then self.lastFiredTime = -1; end
        end
        
    end
    
    cluster.adjecentHumanClusters  = adjecentHumanClusters;
    if(prevActiovation ~= cluster.active) then
        return true;
    else
        return false;
    end
    
end

-- returns keep building belonging to given cluster number
function Map:getClusterKeep(clusterNum)
    local clusterMean = self.clusters[clusterNum].meanTile;
    
    return self:getItem(self.tiles[clusterMean[1]][clusterMean[2]].item);
    
end

-- returns the player owning tile on given coordinates or nil when untaken
function Map:getTileOwner(r, u)
    local clusterNum = self.tiles[r][u].cluster;
    local id = self.clusters[clusterNum].owner;
    return self:getPlayerById(id);
end

-- returns the player owning given cluster or nil when untaken
function Map:getClusterOwner(clusterNum)
    local id = self.clusters[clusterNum].owner;
    return self:getPlayerById(id);
end


function Map:getPlayerById(id)
    if(id == self.humanPlayer.id) then
        return self.humanPlayer;
    end
    
    if(id == self.aiPlayer.id) then
        return self.aiPlayer;
    end
    
    return nil;
end


local function isBorderTile(r, u, clusNum, tiles, size)
    
    if(r< 1 or r > size or u< 1 or u > size) then -- tile out of map
        return false;
    elseif(tiles[r][u].cluster ~= clusNum) then -- tile in another cluster
        return false;
        
    elseif( r == 1 or r == size or u==1 or u==size or -- tile on edge of the map
        tiles[r-1][u].cluster ~= clusNum or -- up, left tile in diferent cluster
        tiles[r][u+1].cluster ~= clusNum or -- up, right  tile in diferent cluster
        tiles[r+1][u].cluster ~= clusNum or -- down,  right in diferent cluster
        tiles[r][u-1].cluster ~= clusNum -- down, left  tile in diferent cluster
        ) then
        
        return true;
    else
        return false;
    end
    
end

function Map:getRandomFreeTileInClususter(clusterNum, forbidBorderTiles)
    local clusterTiles = self.clusters[clusterNum].tiles;
    local tiles = self.tiles;
    local size= self.size;
    local coord;
    
    local index = math.random(1, #clusterTiles);
    
    for num = 1, #clusterTiles do
        coord = clusterTiles[index];
        
        if(self.tiles[coord[1]][coord[2]].item <= 0) then
            if(forbidBorderTiles) then
                if( isBorderTile(coord[1], coord[2], clusterNum, tiles, size) == false) then
                    return coord[1], coord[2];
                end
            else
                return coord[1], coord[2];
            end
        end
        
        index = index +1;
        if(index > #clusterTiles) then
            index = 1;
        end
    end
    
    -- no free tile found, return at least something ...
    return coord[1], coord[2];
    
end

--[[
function Map:toJson(fileName)
    local jsonIO = require("io.jsonIO");
    
    jsonIO:saveTableToFile(fileName, self);
end
]]
return Map;


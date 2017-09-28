

local isoMapGen = {};

local manhattanDist = require("math.geometry").manhattanDist;
local chebyshevDist = require("math.geometry").chebyshevDist;

--local distFun = chebyshevDist;
local giveMeEverything = false;

local pow = math.pow;


-- params {size=num, numOfcenters = num}
function isoMapGen:createNewMap(params, startSet, isoGrid, aiPlayer, humanPlayer)
    
    local map = require("game.map.Map"):new(params, isoGrid,  aiPlayer, humanPlayer);
    local gameConst = require("game.gameConst");
    
    if(params.giveMeEverything) then
        giveMeEverything = true;
    else
        giveMeEverything = false;
    end
    
    --local startSet = params.startSet;
    local maxPowerCat = params.maxPowerCategory;
    
    self:addCenterPoints(map, params.numOfClusters);
    self:clusterTiles(map);
    self:clusterEdges(map);
    self:assignClusterToPlayers(map, humanPlayer, aiPlayer, params.playerHomePosition, false);
    self:setGoalCluster(map, params.goalPosition);
    self:addInClusterPropeties(map, gameConst, maxPowerCat);
    self:addMapItems(map,startSet, humanPlayer,aiPlayer);
    self:addMapTreasures(map,startSet,gameConst, humanPlayer, maxPowerCat);
    self:createClusterPolygons(map); -- creates vertices definong shape of cluster pokygon in cartesion space
    
    return map;
end


local function getIsoFromPosString(map, position)
    local r,u;
    local size = map.size;
    
    if(position == "north")then
        r = 1; u = size;
    elseif(position == "south")then
        r = size; u =1;
    elseif(position == "west")then
        r = 1; u = 1;
    elseif(position == "east")then
        r =size; u = size;
    elseif(position == "center")then
        r = math.floor(size*0.5); u = r;
    elseif(position == "random")then
        r = math.random(1,size); u = math.random(1,size);
    else
        error("Unrecognized goal cluster position : " .. tostring(position));
    end
    
    return r,u;
end

-- regular grid distribution
function isoMapGen:addCenterPoints(map, numOfclusters)
    
    local size = map.size;
    --local num = 0;
    local centersMap = {};
    local iPos,jPos = 0,0;
    local rnd = math.random;
    local floor = math.floor;
    
    
    local count = floor(math.sqrt(numOfclusters));
    local d = floor(size/(count+1));
    --print("d: " .. d)
    -- centroid coordinates max deviation forom regular grid position
    local maxDeviative = floor(d*0.5); 
    --local maxDeviative = d-1;
    if(maxDeviative >= d) then
        maxDeviative = 0;
    end
    --local meanDeviative = 0;
    --local standartdDeviative = 
    
    for i=1, count do
        jPos = d;
        iPos = iPos + d;
        
        for j= 1, count do
            
            local iCoord = iPos;
            local jCoord = jPos;
            
            if(not(i==1 and j==1) and maxDeviative > 0) then
                iCoord = iCoord + rnd(0,maxDeviative);
                jCoord = jCoord + rnd(0,maxDeviative);
            end
            
            if(centersMap[iCoord]) then
                if(centersMap[iCoord][jCoord]== nil) then
                    centersMap[iCoord][jCoord] = true;
                    --num = num+1;
                end
            else
                centersMap[iCoord] = {};
                centersMap[iCoord][jCoord] = true;
                --num = num+1;
            end
            
            jPos = jPos + d;
            
        end
    end
    
    local n = 1;
    local clus = map.clusters;
    for i,row in pairs(centersMap) do
        for j,val in pairs(row) do            
            clus[n].center={i,j};
            n = n+1;
        end
    end
    
    
    --print("mapGen, actual slusters #:" .. (n-1))
    
    -- number of generated centroids can be smaller than requested
    -- so indweling clusters have to be removed from map
    if( n <= numOfclusters) then
        for i= n, numOfclusters do
            table.remove(clus, n);
        end
    end
    
end


--[[
function isoMapGen:addCenterPoints(map, numOfclusters, playerHomeCenterCoord, freeZoneSize)
    
    local size = map.size;
    local num = 0;
    local centersMap = {};
    local i,j;
    local rnd = math.random;
    
    -- add one center for human player home cluster
    local homeI, homeJ = playerHomeCenterCoord[1], playerHomeCenterCoord[2];
    centersMap[homeI] ={};
    centersMap[homeI][homeJ] = true;
    num = 1;
    
    while(num < numOfclusters) do
        
        i = rnd(1,size);
        j = rnd(1,size);
        
        if( distFun(i,j,homeI, homeJ) > freeZoneSize) then
            
            if(centersMap[i]) then
                if(centersMap[i][j]== nil) then
                    centersMap[i][j] = true;
                    num = num+1;
                end
            else
                centersMap[i] = {};
                centersMap[i][j] = true;
                num = num+1;
            end
            
        end
        
    end
    
    local n = 1;
    local clus = map.clusters;
    for i,row in pairs(centersMap) do
        for j,val in pairs(row) do            
            clus[n].center={i,j};
            n = n+1;
        end
    end
    
end
]]

-- brute force centroidal clustering
function isoMapGen:clusterTiles(map)
    
    local distFun = map.distFun;
    local clusters = map.clusters;
    local size =  map.size;
    local tiles = map.tiles;
    --local clusterTiles = {};
    
    
    --for each tile
    for i = 1, size do
        local row = tiles[i];
        for j= 1, size do
            
            local minDist = 2*size; -- distances cannot be bigger than size
            local clusterNum;
            local dist;
            
            -- for each centroid
            for c = 1, #clusters do
                local centroid  = clusters[c].center;
                dist = distFun(i,j,centroid[1],centroid[2]); 
                
                if(dist < minDist) then
                    clusterNum =  c;
                    minDist = dist;
                end
            end
            
            row[j].cluster = clusterNum;
            
            --if(not clusters[clusterNum].tiles) then clusters[clusterNum].tiles =  {} end;
            
            local list = clusters[clusterNum].tiles;
            list[#list+1] = {i,j};
            
        end
    end
    
    -- calculate cluster sizes and its mean point
    local round = math.ceil;
    local isoGrid = map.isoGrid;
    for c = 1, #clusters do
        local tiles  = clusters[c].tiles;
        clusters[c].size = #tiles;
        
        local xSum, ySum = 0,0;
        
        for t = 1 , #tiles do
            local x,y = isoGrid:isoToCart(tiles[t][1],tiles[t][2])
            xSum = xSum + x;
            ySum = ySum + y;
        end
        local r,u = isoGrid:cartToIso(round(xSum/#tiles), round(ySum/#tiles))
        
        -- mean tile inside cluster
        if(map.tiles[r][u].cluster == c)then 
            clusters[c].meanTile= {r,u}
        else
            -- mean tile outside cluster
            local center = clusters[c].center;
            clusters[c].meanTile= {center[1], center[2]};
        end
    end
    
end

-- look at edge surrounding tiles to determine
--- whenever belongd to some cluster or on two custers border
function isoMapGen:clusterEdges(map)
    
    local rightEdges = map.rightEdges;
    local upEdges = map.upEdges;
    local clusters = map.clusters;
    local tiles = map.tiles;
    local size = map.size;
    -- list of edges 
    
    local clusterBorders = {};
    -- alocate memory for border edges 
    --[[
    for i = 1, #clusters do    
        clusters[i].borders = {};
    end
    ]]
    local r,u; -- tile coordinates
    local ceil = math.ceil;
    
    local c1,c2;
    
    for i = 1, #upEdges do
        
        c1 = nil;
        c2=nil;
        
        r =ceil(i/size)-1;
        u = i%size;
        if(u==0) then
            u = size;
        end
        
        if(r > 0) then -- left tile
            c1 = tiles[r][u].cluster;
        end
        
        if(r < size) then -- right tile
            c2 = tiles[r+1][u].cluster;
        end
        
        if( (c1 and c2) == nil) then -- map edge
            upEdges[i] = { clusterPos="in",  cluster=c1 or c2}
        elseif(c1 == c2) then -- inside map, inside cluster
            upEdges[i] = { clusterPos="in",  cluster=c1}
        else -- on clusters edge
            upEdges[i] = { clusterPos="border",  c1=c1, c2=c2}
            
            -- remember border edges for both clusters
            if(clusters[c1].borders[c2] == nil) then clusters[c1].borders[c2] = {} end;
            if(clusters[c2].borders[c1] == nil) then clusters[c2].borders[c1] = {} end;
            local def = {edgeType="up", index = i};
            clusters[c1].borders[c2][#clusters[c1].borders[c2]+1 ] = def;
            clusters[c2].borders[c1][#clusters[c2].borders[c1]+1 ] = def;
            
            clusters[c1].neighbors[c2] = true;
            clusters[c2].neighbors[c1] = true;
        end
        
        
        -- right edges
        c1 = nil;
        c2=nil;
        
        u =ceil(i/size);
        r = i%size;
        if(r==0) then
            r = size;
        end
        
        --print("r,u:" .. r .. "," .. u ) 
        
        if(u <= size) then -- up tile
            c1 = tiles[r][u].cluster;
        end
        
        if(u > 1) then -- down tile
            c2 = tiles[r][u-1].cluster;
        end
        
        if( (c1 and c2) == nil) then -- map edge
            rightEdges[i] = { clusterPos="in",  cluster=c1 or c2}
        elseif(c1 == c2) then -- inside map, inside cluster
            rightEdges[i] = { clusterPos="in",  cluster=c1}
        else -- on clusters edge
            rightEdges[i] = { clusterPos="border",  c1=c1, c2=c2}
            
            -- remember border edges for both clusters
            if(clusters[c1].borders[c2] == nil) then clusters[c1].borders[c2] = {} end;
            if(clusters[c2].borders[c1] == nil) then clusters[c2].borders[c1] = {} end;
            local def = {edgeType="right", index = i};
            clusters[c1].borders[c2][#clusters[c1].borders[c2]+1 ] = def;
            clusters[c2].borders[c1][#clusters[c2].borders[c1]+1 ] = def;
            
            clusters[c1].neighbors[c2] = true;
            clusters[c2].neighbors[c1] = true;
            
        end
    end
end




function isoMapGen:setGoalCluster(map, position)
    
    local r,u = getIsoFromPosString(map, position);
    -- add one goal cluster
    --local goalClusterNum = aiPlayer:getRandomOwnedClusterNumber();
    local goalClusterNum = map.tiles[r][u].cluster;
    local goalCluster = map.clusters[goalClusterNum];
    goalCluster.isGoal = true;
    map.goalClusterNum = goalClusterNum;
end

--[[
see : https://github.com/EmmanuelOga/easing/blob/master/lib/easing.lua
local function inQuart(t, b, c, d)
    t = t / d;
    return c * pow(t, 4) + b
end

local function inCubic (t, b, c, d)
    t = t / d
    return c * pow(t, 3) + b
end
]]
--[[
local function inQuad(t, b, c, d)
    t = t / d
    return c * pow(t, 2) + b
end

local function outCubic(t, b, c, d)
    t = t / d - 1
    return c * (pow(t, 3) + 1) + b
end


local function outQuad(t, b, c, d)
t = t / d
return -c * t * (t - 2) + b
end
]]
local cos = math.cos;
local sin = math.sin;
local pi = math.pi;
local function inOutSine(t, b, c, d)
    return -c / 2 * (cos(pi * t / d) - 1) + b
end

local function outSine(t, b, c, d)
return c * sin(t / d * (pi / 2)) + b
end

function isoMapGen:addInClusterPropeties(map,gameConst, maxPowerCategory)
    
    local list = map.clusters;
    local floor = math.floor;
    --local ceil = math.ceil;
    local rnd = math.random;
    --local id = defaultPlayer.id;
    
    -- cluster power 
    local powerCategories= gameConst.clustersPowerCategories;
    local normalDev = require("math.mathUtils").normalDev;
    local distFun = manhattanDist;
    local size = map.size;
    local humanPlayerCenter = list[map.humanHomeClusterNum].center;
    local goalCenter =  list[map.goalClusterNum].center;
    --local rightCornerCenter =  list[map.tiles[size][size].cluster].center;
    local powerCumulationCoeff = 0.65; -- might partially define difficulty
    local maxDist = distFun(humanPlayerCenter[1],humanPlayerCenter[2],goalCenter[1],goalCenter[2])*powerCumulationCoeff;
    --local maxDist = distFun(1,1,size,size);
    --local maxDist = distFun(1,1,size*0.3,size*0.3);
    --print("maxDist: " .. maxDist);
    local oneCategoryRatingSize = 1/#powerCategories;
    local maxPowerCat = maxPowerCategory or #powerCategories;
    if(maxPowerCat > #powerCategories or type(maxPowerCat)~= "number") then
        print("isoMapGen Warning: max supported power categoty is " .. ##powerCategories .. ", not given: " .. tostring(maxPowerCat));
        maxPowerCat = #powerCategories;
    end;
    --print("max PowerCat: " .. maxPowerCat);
    
    local distanceWeight = 0.5;
    local maxRndCategoryChange =  1;
    local categChangeProb = 0.25;
    
    for i = 1, #list do
        local c = list[i];
        
        local powerProps = c.powerProperties;
        
        
        local center = c.center;
        local dist = distFun(center[1],center[2],goalCenter[1],goalCenter[2]);
        
        local distanceRating = ((maxDist-dist)/maxDist);
        
        if(distanceRating> 1) then 
            distanceRating = 1;
        elseif(distanceRating < 0) then
            distanceRating = 0;
        end;
        
        --powerRating = inQuart(powerRating,0,1,1);
        --local powerRating = inQuad(distanceRating*distanceWeight + rnd()*randomWeight,0,1,1);
        --local powerRating = outSine(distanceRating,0,1,1);--inQuad(distanceRating,0,1,1);
        local powerRating = outSine(distanceRating,0,1,1);
        
        --local powerCategory = rnd(1,#powerCategories);
        local powerCategory = floor( powerRating / oneCategoryRatingSize)+1;
        
        if(rnd() >= categChangeProb) then
            powerCategory = powerCategory+1;  
        elseif(rnd() >= categChangeProb) then 
            powerCategory = powerCategory-1;
        end
        
        if(powerCategory > maxPowerCat) then powerCategory = maxPowerCat; end;
        if(powerCategory <= 0) then powerCategory = 1; end;
        
        powerProps.powerCategory = powerCategory;
        --print("dist: " ..dist .. ", categoryRating:" .. powerRating .. ", power category:" ..powerCategory )
        
        -- def: {damage = {mean=4, sigma =2},  keepToughness = {mean=25, sigma =5} }
        local categoryDef = powerCategories[powerCategory];
        
        local damage = categoryDef.damage;
        if(type(damage) == "number") then
            powerProps.damage = damage;
        else
            powerProps.damage = floor(normalDev(damage.mean, damage.sigma));
            if(powerProps.damage<damage.min) then powerProps.damage = damage.min; end
            if(powerProps.damage>damage.max) then powerProps.damage = damage.max; end
        end
        
        local keepToughness = categoryDef.keepToughness;
        if(type(keepToughness) == "number") then
            powerProps.keepToughness = keepToughness;
        else
            powerProps.keepToughness = floor(normalDev(keepToughness.mean, keepToughness.sigma));
            if(powerProps.keepToughness<1) then powerProps.keepToughness = 1; end
        end
        
        local firePeriod = categoryDef.firePeriod;
        if(type(firePeriod) == "number") then
            powerProps.firePeriod = firePeriod;
        else
            powerProps.firePeriod = floor(normalDev(firePeriod.mean, firePeriod.sigma));
            if(powerProps.firePeriod<1000) then powerProps.firePeriod = 1000; end
        end
        
    end
end



function isoMapGen:assignClusterToPlayers(map, player, aiPlayer,playerHomePosition,  takeNeighborhood)
    
    local clustersList = map.clusters;
    local floor = math.floor;
    local rnd = math.random;
    local id = aiPlayer.id;
    local list = map.clusters;
    
    -- give all clusters to ia player
    for i = 1, #list do
        local c = list[i];
        
        
        c.owner = id;
        aiPlayer:addCluster(i);
    end
    
    id = player.id;
    
    -- take one cluster for human player
    local r,u = getIsoFromPosString(map, playerHomePosition);
    --local clusterNum = rnd(1,#clustersList);
    local clusterNum = map.tiles[r][u].cluster;
    local cluster = clustersList[clusterNum];
    cluster.owner = id;
    map.humanHomeClusterNum = clusterNum;
    
    aiPlayer:removeCluster(clusterNum);
    player:addCluster(clusterNum);
    player.homeCluster = clusterNum;
    
    if(takeNeighborhood) then-- take all neighbors
        local neighbours = cluster.neighbors;
        for k,v in pairs(neighbours) do
            
            clustersList[k].owner = id;
            aiPlayer:removeCluster(k);
            player:addCluster(k);
            --defaultOwner.ownedClusters[k] = false;
            --player.ownedClusters[k] = true;
        end
    end
    
end


function isoMapGen:addMapItems(map,startSet, humanPlayer, aiPlayer)
    
    local clus = map.clusters;
    local n = 0;
    local rnd = math.random;
    local humanId = humanPlayer.id;
    local homeCluster;
    
    
    for i = 1, #clus do
        homeCluster = false;
        
        -- add keep to cluster mean tile
        if(clus[i].owner == humanId) then
            if(i == humanPlayer.homeCluster) then
                homeCluster =  true;
                require("game.map.buildings.HomeKeep"):new(clus[i].meanTile[1],clus[i].meanTile[2],map);
            else
                require("game.map.buildings.Keep"):new(clus[i].meanTile[1],clus[i].meanTile[2],map);
            end
        else
            if(clus[i].isGoal) then
                require("game.map.buildings.EnemyKeep"):new(clus[i].meanTile[1],clus[i].meanTile[2],map, true);
            else
                require("game.map.buildings.EnemyKeep"):new(clus[i].meanTile[1],clus[i].meanTile[2],map);
            end
        end
        
        if(homeCluster) then
            
            --local directions = require("math.geometry").eightDir; 
            --local mean = clus[i].meanTile;
            --local dirIndex = rnd(1,#directions);
            --local dirIndex = 1;
            --local dir = directions[dirIndex];
            
            local r,u = map:getRandomFreeTileInClususter(i, true)
            
            --require("game.map.items.Material"):new(mean[1] + dir[1], mean[2] + dir[2] ,startSet.material,map);
            local material = require("game.map.items.Material"):new(r, u ,startSet.material,map);
            humanPlayer:addMaterial(material);
            
            --local rr,ru = map:getRandomFreeTileInClususter(i);
            --dir = directions[dirIndex+1];
            --require("game.map.items.Bullet"):new(mean[1] + dir[1], mean[2] + dir[2],map);
            r,u = map:getRandomFreeTileInClususter(i, true)
            require("game.map.items.Bullet"):new(r,u,map);
            
            if(giveMeEverything) then
                r,u = map:getRandomFreeTileInClususter(i, true)
                require("game.map.buildings.Gun"):new(r,u,map);
            end
            
            self:addCircumferentialWalls(i, clus[i], map, startSet.wallsDensity);
        end
    end
    
    -- add material deposits
    local n=0
    --for i = 1, startSet.materialDepositsNum do
    while(n < startSet.materialDepositsNum) do
        local clustrNum =  rnd(1, #clus);
        
        if(clustrNum ~= humanPlayer.homeCluster) then
            local r,u = map:getRandomFreeTileInClususter(clustrNum, true);
            require("game.map.items.Material"):new(r,u,startSet.materialDepositsAmount,map);
            n=n+1;
        end
    end
    
    -- add bullets
    n = 0;
    while(n < startSet.bulletsDepositsNum) do
        local clustrNum =  rnd(1, #clus);
        
        if(clustrNum ~= humanPlayer.homeCluster) then
            local r,u = map:getRandomFreeTileInClususter(clustrNum, true);
            require("game.map.items.Bullet"):new(r,u,map);
            n=n+1;
        end
    end
    --[[
    n = 0;
    while(n < startSet.inactiveMinionsCount) do
        local clustrNum =  rnd(1, #clus);
        
        if(clustrNum ~= humanPlayer.homeCluster and #clus[clustrNum].inactiveMinions < 1) then
            local r,u = map:getRandomFreeTileInClususter(clustrNum);
            local minion = require("game.unit.Minion"):new(r,u,map.isoGrid);
            clus[clustrNum].inactiveMinions[#clus[clustrNum].inactiveMinions+1] = minion;
            n= n+1;
        end
    end
    ]]
end

-- density - 0 means no walls are added, 1 means all walls are added
-- TODO this can be simplyfied using variant of idBorderTile() function
function isoMapGen:addCircumferentialWalls(clusterNum, cluster, map, density)
    local border = cluster.borders;
    local size = map.size;
    local tiles = map.tiles;
    local rnd = math.random;
    
    
    local adjecentTiles = {nil, nil, nil, nil}; -- every edge has two adjecent tiles
    
    --local directions = require("math.geometry").eightDir; 
    
    for adjecentCluserNum, adjecentCluserEdges in pairs(border) do
        
        for j,edge in ipairs(adjecentCluserEdges) do
            
            local count  = self:getEdgeAdjecentTiles(edge, size,true,adjecentTiles);
            
            for k=1,count do
                local tileCoord = adjecentTiles[k];
                local r, u = tileCoord[1], tileCoord[2];
                local tile = tiles[r][u];
                
                if(tile.item <= 0 and tile.cluster==clusterNum and rnd() <= density) then  -- free tile inside given cluster
                    require("game.map.buildings.Wall"):new(r,u,map); 
                end 
            end
        end
    end
    
end


function isoMapGen:getEdgeAdjecentTiles(edgeDef, size,exdendedAdjecency,  retArray)
    local adjecentTiles = retArray;
    local i = edgeDef.index;
    local ceil = math.ceil;
    local r,u;
    local count=0;
    
    if(edgeDef.edgeType == "up") then
        -- up edge   
        
        r =ceil(i/size)-1;
        u = i%size;
        if(u==0) then
            u = size;
        end
        
        if(r > 0) then -- left tile
            count = count +1
            adjecentTiles[count] = {r,u};
        end
        
        if(r < size) then -- right tile
            count = count +1
            adjecentTiles[count] = {r+1,u};
        end
        
        if(exdendedAdjecency) then
            if(u < size and r >0) then
                count = count +1
                adjecentTiles[count] = {r,u+1}; -- up tile
            end
            
            if(u < size and r < size) then
                count = count +1
                adjecentTiles[count] = {r+1,u+1}; -- up right tile
            end
            
            if(u > 1 and r > 0)then -- down tile
                count = count +1
                adjecentTiles[count] = {r,u-1};
            end
            
            if(u > 1 and r < size)then -- down right tile
                count = count +1
                adjecentTiles[count] = {r+1,u-1};
            end
            
        end
        
    else
        
        -- right edge
        u =ceil(i/size);
        r = i%size;
        if(r==0) then
            r = size;
        end
        
        --print("r,u:" .. r .. "," .. u ) 
        
        if(u <= size) then -- up tile
            count = count +1;
            adjecentTiles[count] = {r,u};
        end
        
        if(u > 1) then -- down tile
            count = count +1;
            adjecentTiles[count] = {r,u-1};
        end
    end
    
    --TODO : if(exdendedAdjecency) then .. pridat i rozsirene okoli pro right edges 
    
    return count;
    
end

function isoMapGen:addMapTreasures(map,startSet,gameConst, humanPlayer, maxPowerCategory)
    
    local clus = map.clusters;
    local rnd = math.random;
    local humanId = humanPlayer.id;
    local startTreasures = startSet.treasures;
    
    -- for each treasure type in starting set
    for treasureName,tresNum in pairs(startTreasures) do
        local treasureDef = gameConst.treasures[treasureName];
        local minPowerCat = treasureDef.minPowerCategory;
        local count = 0;
        local clusterNum;
        local c;
        local forbidBorderTiles = (treasureName == "empty");
        
        if(minPowerCat <= maxPowerCategory) then
            
            while(count < tresNum) do
                -- select random non human player cluster
                clusterNum = rnd(1,#clus);
                c = clus[clusterNum];
                
                if(c.owner ~= humanId and c.powerProperties.powerCategory >= minPowerCat) then 
                    local r,u = map:getRandomFreeTileInClususter(clusterNum, forbidBorderTiles);
                    if(map.tiles[r][u].item <= 0) then -- it is truly free
                        -- add new treasure
                        -- r,u,map, unlockWorkAmount, treasureName, treasureParams
                        require("game.map.items.Treasure"):new(r,u,map, 
                        treasureDef.workCost, treasureName, treasureDef.params);
                        
                        count = count+1
                    end
                end
            end
        else
            if(tresNum > 0) then
                print("WARNING , isoMapGen: map max power category (".. tostring(maxPowerCategory) ..
                ") is smaller than treasure ".. tostring(treasureName) .. " min power category (".. 
                tostring(minPowerCat).. ")! These trasaures will not be added to the map !");
            end
        end
    end
    
end


local function isBorderTile(r, u, clusNum, tiles, mapSize)
    
    if(r< 1 or r > mapSize or u< 1 or u > mapSize) then -- tile out of map
        return false;
    elseif(tiles[r][u].cluster ~= clusNum) then -- tile in another cluster
        return false;
        
    elseif( r == 1 or r == mapSize or u==1 or u==mapSize or -- tile on edge of the map
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

-- for each cluster creates polygon fully covering all clusters tiles it
-- coordinates of resulting polygon are in cartesian space
function isoMapGen:createClusterPolygons(map)
    
    local clus = map.clusters;
    local tiles = map.tiles;
    local size = map.size;
    local isoGrid = map.isoGrid;
    local borderTilesMap = require("datastructures.Map2D"):new();
    
    for clusNum = 1, #clus do
        --print("clusNum:" .. clusNum)
        borderTilesMap:clear();
        
        -- select first clusters tile on border
        local firstTile;
        local r,u;--, firstR, firstU;
        for index, tile in pairs(map.clusters[clusNum].tiles) do
            -- if lies on border with another cluster or on map edge
            r,u = tile[1], tile[2];
            if( isBorderTile(r,u,clusNum, tiles, size)) then
                firstTile = tiles[r][u];
                --firstR, firstU = r,u;
                borderTilesMap:add(r,u, firstTile);
                break;
                
            end
        end
        
        local centerTile = clus[clusNum].meanTile;
        local cx, cy = isoGrid:isoToCart(centerTile[1],centerTile[2]);
        local x,y = isoGrid:isoToCart(r,u);
        local polyVertices  = { x-cx,y-cy};
        
        local currTile = nil;
        
        local count =0;
        
        while(true) do
            
            -- serch for neighbour of selected tile (just one) also on border
            -- in clockwise direction (up, ur, right, dr, down, dl, left, ul)
            if(isBorderTile(r-1,u+1,clusNum, tiles, size) and borderTilesMap:contains(r-1,u+1)==false ) then -- up
                r,u = r-1, u+1;
                
            elseif(isBorderTile(r,u+1,clusNum, tiles, size) and borderTilesMap:contains(r,u+1)==false) then -- ur
                r,u = r,u+1;
                
            elseif(isBorderTile(r+1,u+1,clusNum, tiles, size) and borderTilesMap:contains(r+1,u+1)==false) then -- right
                r,u = r+1,u+1;
                
            elseif(isBorderTile(r+1,u,clusNum, tiles, size) and borderTilesMap:contains(r+1,u)==false ) then -- dr
                r,u = r+1,u;
                
            elseif(isBorderTile(r+1,u-1,clusNum, tiles, size) and borderTilesMap:contains(r+1,u-1)==false) then -- down
                r,u = r+1,u-1;
                
            elseif(isBorderTile(r,u-1,clusNum, tiles, size)and borderTilesMap:contains(r,u-1)==false) then -- dl
                r,u = r,u-1;
                
            elseif(isBorderTile(r-1,u-1,clusNum, tiles, size) and borderTilesMap:contains(r-1,u-1)==false) then -- left
                r,u = r-1,u-1;
                
            elseif(isBorderTile(r-1,u,clusNum, tiles, size) and borderTilesMap:contains(r-1,u)==false) then -- ul
                r,u = r-1,u;
                
            else -- all border tiles aleady in map
                --print("Warning border tile without neighbour on border ???");
                --currTile = firstTile;
                break;
            end
            
            currTile = tiles[r][u];
            borderTilesMap:add(r,u, currTile);
            count = count+1;
            --print("r, u: ".. r .. ", " .. u);
            
            -- add border coordinates to polygon
            if(currTile ~= firstTile) then
                --TODO a. some coordinates in line with previous ones can optionally be ommited
                
                x,y = isoGrid:isoToCart(r,u);
                polyVertices[#polyVertices+1] = x-cx;
                polyVertices[#polyVertices+1] = y-cy;
            end
            
        end
        
        --print("Border tiles count: " .. count)
        -- add poygon vertices to cluster definition
        clus[ clusNum ].shapeVertices = polyVertices;
        
    end
    
end

return isoMapGen;


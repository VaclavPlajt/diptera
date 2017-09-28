
local IsoMapGraphics = {}

local showDebugLayer =  false;
local abs = math.abs;

function IsoMapGraphics:new(context, layer, map)
    local newIsoMapGraphics = {};
    
    setmetatable(newIsoMapGraphics, self);
    self.__index = self;
    
    
    --newIsoMapGraphics.layer = layer;
    newIsoMapGraphics.isoGrid = map.isoGrid;
    
    newIsoMapGraphics.context = context;
    newIsoMapGraphics.uiConst = context.uiConst;
    newIsoMapGraphics.bounds = context.displayBounds;
    newIsoMapGraphics.img = context.img;
    newIsoMapGraphics.map = map;
    newIsoMapGraphics.clusterColors = self:calcClusterColors(#map.clusters);
    newIsoMapGraphics.requestsMarkers = {}; -- list of minion task requests markers
    newIsoMapGraphics.setShapePolyStyle = require("ui.uiUtils").setShapePolyStyle;
    
    local g = display.newGroup();
    layer:insert(g);
    newIsoMapGraphics.g =g;
    
    -- tiles back group
    local backLayer = display.newGroup();
    g:insert(backLayer);
    newIsoMapGraphics.backLayer = backLayer;
    
    -- minion layer
    local unitLayer = display.newGroup();
    g:insert(unitLayer);
    newIsoMapGraphics.unitLayer = unitLayer;
    
    -- on tiles items group
    local onTilesLayer = display.newGroup();
    g:insert(onTilesLayer);
    newIsoMapGraphics.onTilesLayer = onTilesLayer;
    
    -- on map debug layer
    if(showDebugLayer) then
        local mapDebugLayer = display.newGroup();
        g:insert(mapDebugLayer);
        newIsoMapGraphics.mapDebugLayer = mapDebugLayer;
    end
    
    -- above map layer
    local aboveMapLayer = display.newGroup();
    g:insert(aboveMapLayer);
    newIsoMapGraphics.aboveMapLayer = aboveMapLayer;
    
    -- prepare clusters groups
    
    
    local cl = {};
    for i=1, #map.clusters do
        --local backG = display.newGroup();
        --backLayer:insert(backG);
        
        -- TODO interfers with rendering index and rendering order of mapItems
        --local onTilesG = display.newGroup();
        --onTilesLayer:insert(onTilesG)
        
        --cl[i] = {backGroup=backG, onTilesGroup=onTilesG};
        cl[i] = {shapePolygon=nil};--, onTilesGroup=onTilesG};
    end
    
    newIsoMapGraphics.clusters = cl;
    --newIsoMapGraphics.tiles = {}; -- tiles are no longer rendered individually
    newIsoMapGraphics.units = {};
    newIsoMapGraphics.mapTranslation =  nil;
    --newIsoMapGraphics.scale = 1;
    newIsoMapGraphics.counter = 0;
    --newIsoMapGraphics.mapItems = {}; -- map items
    
    -- add background
    newIsoMapGraphics:addBackground();
    
    -- prepare selection marker
    newIsoMapGraphics:prepareMarkers(newIsoMapGraphics.isoGrid.tileW);
    
    
    -- traverse tile and edges in rendering order
    map.isoGrid:traverseTilesInRenderingOrder(function(right, up, x, y) newIsoMapGraphics:tilesRenderFun(right, up, x, y) end);
    map.isoGrid:traverseEdgesInRenderingOrder(function(edgeType, index, x, y) newIsoMapGraphics:edgeRenderfun(edgeType, index, x, y) end);
    
    
    
    newIsoMapGraphics:addClusterProperties(map);
    
    -- listeners
    newIsoMapGraphics.newUnitListener = function(event) newIsoMapGraphics:onNewUnitCreated(event) end;
    Runtime:addEventListener("unitCreated", newIsoMapGraphics.newUnitListener);
    
    newIsoMapGraphics.unitDestroyedListener = function(event) newIsoMapGraphics:onUnitDestroyed(event) end;
    Runtime:addEventListener("unitDestroyed", newIsoMapGraphics.unitDestroyedListener);
    
    newIsoMapGraphics.newBuildingListener = function(event)  newIsoMapGraphics:addItem(event.building) end;
    Runtime:addEventListener("buildingCreated", newIsoMapGraphics.newBuildingListener);
    
    newIsoMapGraphics.bombLandedListener = function(event) newIsoMapGraphics:showBonbardment(event) end;
    Runtime:addEventListener("bombLanded", newIsoMapGraphics.bombLandedListener);
    
    --pokus
    --[[
    local pokusMark = display.newCircle(aboveMapLayer, newIsoMapGraphics.isoGrid.minX, newIsoMapGraphics.isoGrid.centerY, 20);
    timer.performWithDelay(250, 
    function()
        
        local x,y = g:localToContent(pokusMark.x,pokusMark.y);
        Runtime:dispatchEvent({name="soundrequest", type="playnammed", soundName="enemy_missile_explode", x=x, y=y}); -- play sound
    end, -1);
    ]]
    return newIsoMapGraphics;
end

--[[
function IsoMapGraphics:isOnScreen(x,y)
    
    local g = self.g;
    --local shiftedX, shifeddY = 
    local contX,contY = g:localToContent(x,y);
    -- is within display bounds ?
    local bounds = self.bounds;
    
    if(contX >= bounds.minX and contX<=bounds.maxX 
        and contY >= bounds.minY and contY<=bounds.maxY )then
        print("is on screen");
    else
        print("is off screen");
    end
        
    
    
end
]]

function IsoMapGraphics:dispose()
    if(self.g) then
        Runtime:removeEventListener("unitCreated", self.newUnitListener);
        Runtime:removeEventListener("buildingCreated", self.newBuildingListener);
        Runtime:removeEventListener("bombLanded", self.bombLandedListener);
        Runtime:removeEventListener("unitDestroyed", self.unitDestroyedListener);
        
        self.g:removeSelf();
        self.g = nil;
        
        for key,unit in pairs(self.units) do
            if(unit.destroy) then
                unit:destroy();
            end
        end
        self.units =nil;
        self.disposed = true;
    end 
    
end

function IsoMapGraphics:prepareMarkers(tileWidth)
    
    -- selection maker
    local w = tileWidth*1.3;
    local marker = display.newPolygon( 0, 0, {-w*0.5,0,0,-w*0.25,w*0.5,0,0,w*0.25} );
    marker.fill = {1,0.2};
    marker.strokeWidth = 4;
    marker.stroke = {type="image", filename = "img/comm/fuzy_stroke.png"};
    marker:setStrokeColor(0.5, 0.2,0.2);
    marker.fadeTransiton = nil;
    marker.alpha = 0;
    --marker.blendMode = "add";
    self.backLayer:insert(marker);
    self.selectionMarker = marker;
    
    -- wrong selection marker
    --marker = self.img:newImg{cx=0,cy=0, dir= "mockup", name="wrongSelectionMark"};
    marker = display.newImageRect( self.aboveMapLayer, "img/comm/wrongSelection.png",tileWidth, tileWidth*0.5)
    --{cx=0,cy=0, dir= "mockup", name="wrongSelectionMark"};
    marker.fadeTransition = nil;
    marker.alpha = 0;
    --self.aboveMapLayer:insert(marker);
    self.wrongSelectionMarker = marker;
    
end

function IsoMapGraphics:translateToCluster(clusterNum)
    
    local isoCoord = self.map.clusters[clusterNum].meanTile;
    local x,y = self.isoGrid:isoToCart(isoCoord[1],isoCoord[2]);
    
    local cx = self.bounds.centerX;
    local cy = self.bounds.centerY;
    
    if(self.mapTranslation) then
        transition.cancel(self.mapTranslation);
    end
    
    self.mapTranslation = transition.to(self.g, 
    { 
        x=cx-x, y=cy-y, time = 500,
        onComplete = function() self.mapTranslation = nil; end
    });
    
end


function IsoMapGraphics:addBackground()
    local isoGrid = self.map.isoGrid;
    
    local uiUtils = require("ui.uiUtils");
    self.backPolygon = uiUtils.mapBackground(self.backLayer, isoGrid, self.uiConst);
    
    --[[
    local textureSize = 512;
    display.setDefault( "textureWrapX", "repeat" )
    display.setDefault( "textureWrapY", "repeat" )
    
    local back = display.newPolygon(self.backLayer, isoGrid.centerX, isoGrid.centerY, 
    {isoGrid.minX, isoGrid.centerY, isoGrid.centerX, isoGrid.minY, isoGrid.maxX, isoGrid.centerY, isoGrid.centerX, isoGrid.maxY}
    );
    
    back.fill = {type="image", filename= "img/back.png"}
    --back:setFillColor(0.5,0.5)
    --local s = textureSize/isoGrid.width; print("W: " .. isoGrid.width .. ", S:" .. s .. "repeated:" .. 1/s .." times")
    
    back.fill.scaleX = textureSize/isoGrid.width;
    back.fill.scaleY = textureSize/isoGrid.height;
    
    back.blendMode = "add";
    back.alpha = self.uiConst.mapBackgroundAlpha;-- 0.4;
    
    display.setDefault( "textureWrapX", "clampToEdge" )
    display.setDefault( "textureWrapY", "clampToEdge" )
    ]]
end

function IsoMapGraphics:showBonbardment(event)
    --print("IsoMapGraphics:showBonbardment(event)");
    local r,u,areaSize = event.r, event.u, event.areaSize;
    
    local tileWidth = self.isoGrid.tileW;
    local tileHeight = self.isoGrid.tileH;
    local x,y = self.isoGrid:isoToCart(r,u);
    
    local areaMarker = display.newPolygon( 0, 0, {
        -tileWidth*0.5-(areaSize-1)*tileWidth ,0,
        0,-tileWidth*0.25-(areaSize-1)*tileHeight,
        tileWidth*0.5+(areaSize-1)*tileWidth,0,
    0,tileWidth*0.25+(areaSize-1)*tileHeight} );
    
    areaMarker.x = x;
    areaMarker.y = y;
    areaMarker.fill = {0.97,0.67,0.27,0.8};
    --areaMarker.strokeWidth = 3;
    --areaMarker:setStrokeColor(1);
    areaMarker.fadeTransiton = transition.to(areaMarker, {alpha = 0, time = 1000, onComplete = function() areaMarker:removeSelf() end})
    
    self.onTilesLayer:insert(areaMarker);
end

function IsoMapGraphics:showSelection(r,u, persist)
    local x,y = self.isoGrid:isoToCart(r,u);
    
    local marker = self.selectionMarker;
    
    marker.alpha = 1;
    marker.x = x;
    marker.y = y;
    
    if(marker.fadeTransition) then
        transition.cancel(marker.fadeTransition);
    end
    
    if( not persist) then
        marker.fadeTransition =  transition.to(marker,
        {alpha=0.2, delay= 50, time=250,
        onComplete = function() marker.fadeTransition = nil; end}
        );
    end
    
end

function IsoMapGraphics:showWrongSelection(r,u)
    local x,y = self.isoGrid:isoToCart(r,u);
    
    local marker = self.wrongSelectionMarker;
    
    marker.alpha = 1;
    marker.x = x;
    marker.y = y;
    
    if(marker.fadeTransition) then
        transition.cancel(marker.fadeTransition);
    end
    
    marker.fadeTransition =  transition.to(marker,
    {alpha=0, delay= 50, time=250,
    onComplete = function() marker.fadeTransition = nil; end}
    );
    
    -- play sound
    Runtime:dispatchEvent({name="soundrequest", type="playnammed", soundName="wrong"});--, x=x, y=y});      
    
end

local function calcPolygonBoundingBoxCenter(cx, cy, shapeVert)
    local maxX,maxY, minX, minY = shapeVert[1], shapeVert[2], shapeVert[1], shapeVert[2];
    
    
    for i =1, #shapeVert, 2 do
        local x,y = shapeVert[i], shapeVert[i+1];
        
        if(x > maxX) then
            maxX = x;
        end
        
        if(x< minX) then
            minX = x;
        end
        
        if(y>maxY) then
            maxY = y;
        end
        
        if(y<minY) then
            minY = y;
        end
    end
    
    return abs(maxX-minX), abs(maxY-minY), cx+(minX+maxX)*0.5, cy+(minY+maxY)*0.5;
    
end



function IsoMapGraphics:addClusterProperties(map)
    
    local isoGrid = map.isoGrid;
    local list = map.clusters;
    --local tileW = self.isoGrid.tileW;
    
    for i= 1, #list do
        local cluster = list[i]; 
        local g = self.backLayer;--self.clusters[i].backGroup;
        
        -- add inactive minions
        for index, minion in pairs(cluster.inactiveMinions) do
            --print("adding inactive minon..")
            self:initUnitGraphics(minion.r, minion.u, minion);
        end
        
        
        -- get cluster player color
        local player = map:getClusterOwner(i);
        
        
        -- add cluster shape polygon
        local center = cluster.meanTile;
        local shapeVert = cluster.shapeVertices;
        
        local cx,cy = isoGrid:isoToCart(center[1],center[2]);
        local polyW,polyH,polyCx, polyCy =  calcPolygonBoundingBoxCenter(cx, cy, shapeVert);
        local dx,dy = (polyCx-cx), (polyCy-cy);
        --local shapePoly = display.newPolygon(self.aboveMapLayer, cx + (polyCx-cx), cy + (polyCy-cy), shapeVert);
        local shapePoly = display.newPolygon(g, cx + dx, cy + dy, shapeVert);
        --shapePoly.strokeWidth = 4;
        
        shapePoly.fill = {type="image", filename= "img/comm/patt2.png"}
        local fi = shapePoly.fill;
        fi.x = dx/polyW;
        fi.y = dy/polyH;
        
        -- set fill style
        self.setShapePolyStyle(shapePoly, player.isAI, self.uiConst);
        
        
        self.clusters[i].shapePolygon = shapePoly;
        
        if(showDebugLayer) then 
            -- show vertices of cluster shape polygon
            local star;
            
            for i =1, #shapeVert, 2 do
                local x,y = cx+shapeVert[i], cy+shapeVert[i+1];
                
                if(i==1) then
                    star = display.newLine(self.aboveMapLayer,cx,cy, x,y)
                    star:setStrokeColor( 0.7, 0.5, 0, 1 )
                    star.strokeWidth = 1
                else
                    star:append( x,y );
                end
                
                local centerMark = display.newCircle(x,y, 3 )
                self.aboveMapLayer:insert(centerMark);
                centerMark:setFillColor(0.0,1.0,0.5,1);
                local label = display.newText( math.ceil(i*0.5), x+10, y, native.systemFont, 14 )
                label:setFillColor(1,0,0,1);
                self.aboveMapLayer:insert(label);
            end
            
            local centerMark = display.newCircle(cx, cy, 6 )
            self.aboveMapLayer:insert(centerMark);
            centerMark:setFillColor(1,0.5,0.0,1);
            
            local polyCenterMark = display.newCircle(polyCx, polyCy, 4 )
            self.aboveMapLayer:insert(polyCenterMark);
            polyCenterMark:setFillColor(0.0,0.5,1.0,1);
            
            
            -- add center point
            local center = cluster.center;
            local x,y = isoGrid:isoToCart(center[1],center[2]);
            local centerMark = display.newCircle(x, y, 3 )
            g:insert(centerMark);
            centerMark:setFillColor(1,0.5,0.0,1);
            
            -- add text
            --local myText = display.newText("#" .. i .. ",s:".. cluster.size .. ",i:" .. cluster.influence .. ",o:" .. cluster.owner , x, y+14, native.systemFont, 14 )
            local s = "#" .. i .. ",s:".. cluster.size .. ",o:" .. cluster.owner .. ", p:" .. cluster.powerProperties.powerCategory;
            
            if(cluster.isGoal) then
                s =  s .. ", GOAL!";
                local gx, gy = x,y;
                local flag =self.img:newImg{dir= "mockup", name="goalMark", group=self.aboveMapLayer, cx=x, cy =y};
                flag.x = gx + flag.width*0.5;
                flag.y = gy - flag.height*0.5;
            end
            
            
            local myText = display.newText(s , x, y+14, native.systemFont, 14 )
            --myText:setFillColor(0.9,0.3,0.2,1);
            g:insert(myText);
        end
        
    end
    
end

--[[
function IsoMapGraphics:colorTile(r, u, color)
    local tile = self.tiles[r][u];
    tile:setFillColor(unpack(color));
end
]]


function IsoMapGraphics:clusterChangedOwner(clusterNum)
    local map = self.map;
    local cluster = map.clusters[clusterNum];
    --local newColor;
    --local clusterColor = self.clusterColors[clusterNum];
    local shapePoly = self.clusters[clusterNum].shapePolygon;
    
    local endScale;
    local hasOwner = cluster.owner > 0;
    
    if(hasOwner) then -- has owner
        local player = map:getClusterOwner(clusterNum);
        self.setShapePolyStyle(shapePoly, player.isAI, self.uiConst);

        --shapePoly:setFillColor(unpack(color));
        shapePoly.isVisible = true;
        shapePoly.xScale = 0.1;
        shapePoly.yScale = 0.1;
        endScale = 1;
    else -- is neutral
        --shapePoly.xScale = 0.1;
        --shapePoly.yScale = 0.1;
        endScale = 0.1;
    end
    
    -- set shape polygon color
    
    
    -- cancel all possible
    transition.cancel(shapePoly);
    --local fi = shapePoly.fill;
    --transition.cancel(fi);
    
    transition.to(shapePoly, {xScale = endScale, yScale = endScale, time = 650,
        onComplete = function()
            if(hasOwner== false) then
                shapePoly.isVisible = false;
            end
        end
    });
    
    --[[
    if(hasOwner) then
        fi.effect.numTiles = 54;
        -- Transition the filter to full intensity over the course of 2 seconds
        transition.to( fi.effect, { time=5000, numTiles=64, transition=easing.outSine } )
    end
    ]]
    
    -- tiles are no longer rendered separattelly
    --for index, tileCoord in pairs(cluster.tiles) do
    
    --   local tileBack = self.tiles[tileCoord[1]][tileCoord[2]];
    
    --   tileBack:setFillColor(unpack(newColor));
    
    --end
    
    
end

function IsoMapGraphics:tilesRenderFun(right, up, x, y)
    
    
    
    self.counter = self.counter +1;
    
    --return;
    
    
    local tile = self.map.tiles[right][up];
    
    
    -- add tile background
    --[[
    local tileW = self.isoGrid.tileW;
    local tileBack = display.newPolygon( x, y, {-tileW*0.5,0,0,-tileW*0.25,tileW*0.5,0,0,tileW*0.25} );
    --tileBack:setFillColor(0.5 + math.random()*0.2);
    
    local clusterNum = tile.cluster;
    local cluster = self.map.clusters[clusterNum];
    local clusterGraphics = self.clusters[clusterNum];
    
    --local clusterColor = self.clusterColors[clusterNum];
    local playerColor = self.theme.playerColors[cluster.owner];    
    tileBack:setFillColor(unpack(playerColor));
    clusterGraphics.backGroup:insert(tileBack);
    
    -- remember tile background 
    if(self.tiles[right] == nil) then self.tiles[right] = {}; end;
    self.tiles[right][up] = tileBack;
    ]]
    
    -- add item graphics
    if(tile.item > 0) then
        --print("adding item to map grahics r, u: " .. right .. ", " .. up)
        local mapItem =  self.map:getItem(tile.item);
        self:addItem(mapItem, x, y);
    end
    
    
end

-- x,y - coordinates are optional

function IsoMapGraphics:addItem(mapItem, x, y)
    local cx,cy =x,y;
    
    if(cx == nil or cy == nil) then
        cx,cy = self.isoGrid:isoToCart(mapItem.r,mapItem.u);
    end
    
    if(mapItem.typeName == "Gun") then
        mapItem:initGraphics(cx,cy,self.onTilesLayer, self.aboveMapLayer, self.img,self.mapDebugLayer);
    else
        mapItem:initGraphics(cx,cy,self.onTilesLayer, self.img,self.mapDebugLayer);
    end
    
end


function IsoMapGraphics:edgeRenderfun(edgeType, index, x, y)
    
    --local thickness = math.random(0,4);
    --local img = self.context.img:newImg{dir= dir , name=imgName, group=self.layer,cx=x, cy = y};
    local edge;
    local edgeColor = self.uiConst.clusterEdgeColor;-- {0.5,0.3,0.2};--{0.8,0.5,0.6}
    
    
    if (edgeType == "up") then
        edge = self.map.upEdges[index];
    else
        edge = self.map.rightEdges[index];
    end
    
    
    
    if(edge.clusterPos=="border") then
        
        local tileW = self.isoGrid.tileW;
        local edgeMark;
        
        if (edgeType == "up") then
            --local upEdgeMark;
            edgeMark = display.newLine(self.backLayer, x-tileW*0.25, y+tileW*0.125, x+tileW*0.25, y-tileW*0.125);
        else
            --local rightEdgeMark;
            edgeMark = display.newLine(self.backLayer, x-tileW*0.25, y-tileW*0.125, x+tileW*0.25, y+tileW*0.125);
            --rightEdgeMark.anchorSegments = true;
        end 
        
        
        edgeMark.strokeWidth = 6;
        edgeMark.stroke = {type = "image", filename = "img/comm/fuzy_stroke.png"};
        edgeMark.blendMode= "add";
        edgeMark.alpha = 0.75;
        edgeMark:setStrokeColor(unpack(edgeColor));
        
    end
end


function IsoMapGraphics:calcClusterColors(numOfClusters)
    
    local colors = {};
    local step = 1/(numOfClusters+2);
    local val = step;
    
    for i=1, numOfClusters do
        val = val + step;
        colors[i] = val;
    end
    
    return colors;
end


function IsoMapGraphics:renderPath(path, debugInfo)
    if(self.pathGroup) then
        self.pathGroup:removeSelf();
    end
    
    local group = display.newGroup();
    self.g:insert(group)
    self.pathGroup = group;
    local isoGrid = self.isoGrid;
    local nodeData;
    local tileW = self.isoGrid.tileW;
    
    
    -- render closed map
    local color = {0,0.8,0,0.5};
    local function callback(r,u,nodeData)
        --print("closed:" .. r .. ", " .. u);
        local x,y = isoGrid:isoToCart(nodeData[1], nodeData[2]);
        local tileBack = display.newPolygon( x, y, {-tileW*0.5,0,0,-tileW*0.25,tileW*0.5,0,0,tileW*0.25} );
        
        local g = nodeData[5]/debugInfo.pathCost;
        tileBack:setFillColor(color[1]*g,color[2]*g, color[3]*g, color[4]);
        group:insert(tileBack);
    end
    
    debugInfo.closedMap:iterate(callback);
    
    -- render open map
    color  = {0,0,0.8,0.5};
    debugInfo.openMap:iterate(callback);
    
    -- render line along path
    if(#path > 1) then
        local lineData = {}
        for i= 1, #path do
            
            nodeData = path[i];
            local x,y = isoGrid:isoToCart(nodeData[1], nodeData[2]);
            
            lineData[#lineData + 1] = x;
            lineData[#lineData + 1] = y;
            
        end
        
        local pathLine = display.newLine(group,unpack(lineData));
        pathLine.strokeWidth = 2;
        pathLine:setStrokeColor(0.9, 0.2,0.2);
    end
    
end


function IsoMapGraphics:onNewUnitCreated(event)
    
    local unit = event.unit;
    
    self:initUnitGraphics(event.r,event.u,unit);
    self.units[unit] = unit;
end

function IsoMapGraphics:onUnitDestroyed(event)
    local unit = event.unit;
    self.units[unit] = nil;
end

function IsoMapGraphics:initUnitGraphics(r,u,unit)
    
    local layer;
    local unitType = unit.unitType;
    
    if(unitType == "Missile" or unitType == "Bonus")then
        layer = self.aboveMapLayer;
        --elseif(unitType == "EnemyMissile" ) then
        --    print("enemy missile")
        --    layer = self.
    else
        layer = self.unitLayer;
    end
    
    local x,y = self.map.isoGrid:isoToCart(r,u);
    
    if(unitType == "Minion") then
        unit:initGraphics(x,y,layer,self.aboveMapLayer, self.img, self.mapDebugLayer)
    elseif(unitType == "EnemyMissile") then
        unit:initGraphics(x,y,layer, self.aboveMapLayer, self.img, self.mapDebugLayer);
    else
        unit:initGraphics(x,y,layer, self.img, self.mapDebugLayer)
    end
    
end

function IsoMapGraphics:addRequestMark(action, request)
    local mark = require("game.unit.task.RequestMark"):new(action,request);
    mark:createGraphics(self.aboveMapLayer, self.img, self.isoGrid);
    --mark:createGraphics(nil, self.img, self.isoGrid);
    
    self.requestsMarkers[request] = mark; -- remember mark to be able to delete it in future
end

function IsoMapGraphics:removeRequestMark(request)
    local mark = self.requestsMarkers[request];
    mark:remove();
    self.requestsMarkers[request] = nil;
end

return IsoMapGraphics;


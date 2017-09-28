
local function coordTransformtionsTest(isoGrid)
    local x,y = isoGrid:isoToCart(1, 1);
    print("[x,y]=[" .. x .. ", " .. y .. "]"); -- 2,5
    
    x,y = isoGrid:isoToCart(5, 5);
    print("[x,y]=[" .. x .. ", " .. y .. "]"); -- 18,5
    
    x,y = isoGrid:isoToCart(3, 2);
    print("[x,y]=[" .. x .. ", " .. y .. "]"); -- 8,6
    
    
    x,y = isoGrid:isoToCart(10, 10);
    print("[x,y]=[" .. x .. ", " .. y .. "]"); -- -1, -1;
    
    print("-----------")
    local r,u = isoGrid:cartToIso( 3 , 6 );
    print("[r,u]=[" .. r .. ", " .. u .. "]"); -- 2,1
    
    r,u = isoGrid:cartToIso( 2 , 5 );
    print("[r,u]=[" .. r .. ", " .. u .. "]"); -- 1,1
    
    r,u = isoGrid:cartToIso( 19 , 5 );
    print("[r,u]=[" .. r .. ", " .. u .. "]"); -- 5,5
    
    r,u = isoGrid:cartToIso( 11 , 9 );
    print("[r,u]=[" .. r .. ", " .. u .. "]"); -- 5,1
end

local function nodesCoordTransformtionsTest(isoGrid)
    local x,y = isoGrid:nodeIsoToCart(1, 1);
    print("[x,y]=[" .. x .. ", " .. y .. "]"); -- 0,5
    
    local x,y = isoGrid:nodeIsoToCart(2, 1);
    print("[x,y]=[" .. x .. ", " .. y .. "]"); -- 2,6
    
    x,y = isoGrid:nodeIsoToCart(5, 5);
    print("[x,y]=[" .. x .. ", " .. y .. "]"); -- 16,5
    
    x,y = isoGrid:nodeIsoToCart(3, 2);
    print("[x,y]=[" .. x .. ", " .. y .. "]"); -- 6,6
    
    x,y = isoGrid:nodeIsoToCart(6, 6);
    print("[x,y]=[" .. x .. ", " .. y .. "]"); -- 20,5
    
    x,y = isoGrid:nodeIsoToCart(2, 5);
    print("[x,y]=[" .. x .. ", " .. y .. "]"); -- 10,2
    
    x,y = isoGrid:nodeIsoToCart(10, 10);
    print("[x,y]=[" .. x .. ", " .. y .. "]"); -- -1, -1;
    
    print("-----------")
    local r,u = isoGrid:nodeCartToIso( 3 , 6 );
    print("[r,u]=[" .. r .. ", " .. u .. "]"); -- 2,1
    
    r,u = isoGrid:nodeCartToIso( 1.5 , 5 );
    print("[r,u]=[" .. r .. ", " .. u .. "]"); -- 1,1
    
    r,u = isoGrid:nodeCartToIso( 19.5 , 5 );
    print("[r,u]=[" .. r .. ", " .. u .. "]"); -- 6,6
    
    r,u = isoGrid:nodeCartToIso( 11 , 8.2 );
    print("[r,u]=[" .. r .. ", " .. u .. "]"); -- 5,2
    
    r,u = isoGrid:nodeCartToIso( 12 , 0.8 );
    print("[r,u]=[" .. r .. ", " .. u .. "]"); -- 2,6
    
end

local isoGrid;
local counter = 0;
local edgeCounter = 0;
local tileW = 100;
local mapSize = 9;
local upEdgeMark;
local rightEdgeMark;
local nodeMark;
local rightEdgeColor = { 0.75, 0, 0.75};
local upEdgeColor = {  1, 1, 0};

local function tileRenderTest(right, up, x, y)
    --print("right, up, x, y: " .. right .."," .. up .."," .. x .."," .. y);
    counter = counter +1;
    
    --local tileBack = display.newPolygon( x, y, {x-tileH,y,x,y-tileH*0.5,x+tileH,y,x,y+tileH*0.5} );
    local tileBack = display.newPolygon( x, y, {-tileW*0.5,0,0,-tileW*0.25,tileW*0.5,0,0,tileW*0.25} );
    tileBack:setFillColor(math.random()*0.7);
    
    
    local myText = display.newText("[".. right .. "," .. up .. "] " .. "#"..counter, x, y, native.systemFont, 12 )
    
end

local function gridLineRenderTest(x1,y1,x2,y2)
    --print("x1,y2,x2,y2: " .. x1 .."," .. y1 .."," .. x2 .."," .. y2);
    
    --local tileBack = display.newPolygon( x, y, {x-tileH,y,x,y-tileH*0.5,x+tileH,y,x,y+tileH*0.5} );
    local line = display.newLine( x1, y1, x2, y2);
    line.strokeWidth = 2;
    line:setStrokeColor( 0.4,0.4,0.2 )
    --line:setStrokeColor( math.random()*0.7, 0.85, 0, 1 )
    --line:setFillColor(math.random()*0.7);
end


local function edgeRenderTest(edgeType, index, x, y)
    --print("right, up, x, y: " .. right .."," .. up .."," .. x .."," .. y);
    edgeCounter = edgeCounter +1;
    
    --local tileBack = display.newPolygon( x, y, {x-tileH,y,x,y-tileH*0.5,x+tileH,y,x,y+tileH*0.5} );
    --local tileBack = display.newPolygon( x, y, {-tileW*0.5,0,0,-tileW*0.25,tileW*0.5,0,0,tileW*0.25} );
    --tileBack:setFillColor(math.random()*0.7);
    
    --local s = "[".. edgeType .. "," .. index .. "] " .. "#"..counter
    local s = "#"..edgeCounter
    local myText = display.newText(s, x, y, native.systemFont, 14 )
    if(edgeType == "up") then
        myText:setFillColor(unpack(upEdgeColor));
    else
        myText:setFillColor(unpack(rightEdgeColor));
    end
    
end


-- tap detection test
-- TODO zvetsit okraje
local function tapListener(event)
    local r,u = isoGrid:cartToIso(event.x, event.y);
    print("detector tapped at: " .. event.x .. ", " .. event.y .. " which is " .. r .. ", " .. u .. " tile");
    r,u = isoGrid:nodeCartToIso(event.x, event.y);
    --print("[r,u]: [" .. r .. ", " .. u .. "] node");
    
    local x,y = isoGrid:nodeIsoToCart(r,u);
    
    nodeMark.x = x;
    nodeMark.y = y;
    
    local edgeType, index  = isoGrid:edgeCartToIso(event.x,event.y);
    print("[edgeType,index]: [" .. edgeType .. ", " .. index .. "] edge");
    
    x,y = isoGrid:edgeIsoToCart(edgeType,index);
    
    if(edgeType == "up") then
        upEdgeMark.x = x;
        upEdgeMark.y = y;
    else
        rightEdgeMark.x = x;
        rightEdgeMark.y = y;
    end
    
    --nodeMark.x = x;
    --nodeMark.y = y;
    
end

-------------------------------------------- TESTS
-- coordinates test
--isoGrid = require("game.map.IsometricGrid"):new{mapSize=5,tileW=4};
--coordTransformtionsTest(isoGrid);
--nodesCoordTransformtionsTest(isoGrid);

-- rendering test
isoGrid = require("game.map.IsometricGrid"):new{mapSize=mapSize,tileW=tileW};
isoGrid:traverseTilesInRenderingOrder(tileRenderTest);

-- add blue tap listener
local tapDetector = display.newPolygon( isoGrid.centerX, isoGrid.centerY, 
{-isoGrid.width*0.5,0,0,isoGrid.height*0.5, isoGrid.width*0.5,0,0,-isoGrid.height*0.5} );
tapDetector:setFillColor(0.2,0.3,0.7, 0.35);
tapDetector:addEventListener("tap", tapListener);

isoGrid:traverseGridLines(gridLineRenderTest);
isoGrid:traverseEdgesInRenderingOrder(edgeRenderTest)








-- add lines to mark specific edges
upEdgeMark = display.newLine(isoGrid.originX, isoGrid.originY, isoGrid.originX+tileW*0.5, isoGrid.originY-tileW*0.25);
upEdgeMark.strokeWidth = 5;
upEdgeMark:setStrokeColor(unpack(upEdgeColor));
upEdgeMark.anchorSegments = true;


rightEdgeMark = display.newLine(isoGrid.originX, isoGrid.originY, isoGrid.originX+tileW*0.5, isoGrid.originY+tileW*0.25);
rightEdgeMark.strokeWidth = 5;
rightEdgeMark:setStrokeColor( unpack(rightEdgeColor));
rightEdgeMark.anchorSegments = true;

-- add circle to mark specific node
nodeMark = display.newCircle( isoGrid.originX, isoGrid.originY, 5 )
nodeMark:setFillColor(1,0.5,0.5);
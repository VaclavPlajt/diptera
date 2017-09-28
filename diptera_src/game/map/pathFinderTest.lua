

local pathFinderTest = {};




function pathFinderTest:init(isoMapGraphics, map )
    self.isoMapGraphics = isoMapGraphics;
    self.isoGrid = map.isoGrid;
    self.map = map;
    
    
    self.pathFinder = require("game.map.PathFinder"):new();
    --self.r1=nil; self.u1; self.r2; self.u2;
    self.first = true;
    
    -- start end node marks
    local tileW = map.isoGrid.tileW;
    local g = isoMapGraphics.onTilesLayer;
    local startTile = display.newPolygon( 0, 0, {-tileW*0.5,0,0,-tileW*0.25,tileW*0.5,0,0,tileW*0.25} );
    startTile:setFillColor(0,0);
    startTile.strokeWidth = 2;
    startTile.stroke = { 0.6, 0.08, 0.16 }
    g:insert(startTile);
    self.startTile = startTile;
    
    
    local goalTile = display.newPolygon( 0, 0, {-tileW*0.5,0,0,-tileW*0.25,tileW*0.5,0,0,tileW*0.25} );
    goalTile:setFillColor(0,0);
    goalTile.strokeWidth = 2;
    goalTile.stroke = { 0.16, 0.6, 0.08 }
    g:insert(goalTile);
    self.goalTile = goalTile;
    
    Runtime:addEventListener("tiletapped",function(event) self:onTileTapped(event) end);
    
end


function pathFinderTest:tileAccessible(r,u)
    local size = self.map.size;
    if(u > 0 and u <= size and r >0 and r <= size) then 
        return true;
    end
    
    return false;
end

function pathFinderTest:onTileTapped(event)
    
    print("tile:" .. event.r .. ", " .. event.u .. " tapped");
    
    if(self.first) then
        self.r1 = event.r; self.u1= event.u;
        local x,y = self.isoGrid:isoToCart(self.r1, self.u1);
        self.startTile.x = x; self.startTile.y = y;
    else
        self.r2 = event.r; self.u2= event.u;
        local x,y = self.isoGrid:isoToCart(self.r2, self.u2);
        self.goalTile.x = x; self.goalTile.y = y;
        
        local path, debugInfo  = self.pathFinder:findPath(self.r1,self.u1,self.r2,self.u2,
            function(r,u) return self:tileAccessible(r,u) end ,nil, true);
            
        print("path found, lenght: " .. #path);
        
        if(#path > 0) then
            print("input: sr,su:" .. self.r1 .. ", " .. self.u1.. ", gr,gu:" .. self.r2 .. ", " .. self.u2 );
            print("path start: " .. path[1][1] .. ", " .. path[1][2]);
            print("path end: " .. path[#path][1] .. ", " .. path[#path][2] .. " with cost g(n):" .. path[#path][5]);
            print("Visited nodes (including repeated visits) :" .. debugInfo.visitedNodes);
            print("Remembered nodes :" .. debugInfo.rememberedNodes); 
            print("Expanded nodes :" .. debugInfo.expandedNodes);
        end
        
        self.isoMapGraphics:renderPath(path, debugInfo);
    end
    
    self.first = not self.first;
    
end












return pathFinderTest;


-- data structure only, no graphics, no event handling


-- see:
-- http://www.wildbunny.co.uk/blog/2011/03/27/isometric-coordinate-systems-the-modern-way/
-- http://flarerpg.org/tutorials/isometric_intro/
-- http://gamedevelopment.tutsplus.com/tutorials/creating-isometric-worlds-a-primer-for-game-developers--gamedev-6511
local IsometricGrid = {}

local ceil = math.ceil;
local modf = math.modf;

local function round(x)
    local i,f = modf(x);
    
    if(f<0.5) then
        return i;
    else
        return i+1;
    end
    
end


--[[
local function initGrid(grid, params)
    
end
]]


--[[ 
params: {
    mapSize=number of tiles in right and up,
    tileW=tile width, tile height = tileW/2,
    cx = grid center position X coordinate,
    cx = grid center position Y coordinate,
    }
]]
function IsometricGrid:new(params)
    local newGrid = {}; -- create new object
    
    -- set meta tables so lookups will work
    setmetatable(newGrid, self)
    self.__index = self
    
    -- initialize grid
    --initGrid(newGrid, params)
    local cx = params.cx or 0;
    local cy = params.cy or 0;
    
    -- tiles params
    newGrid.tileW = params.tileW;
    newGrid.tileH = params.tileW*0.5;
    
    
    -- map size
    newGrid.size = params.mapSize;
    
    newGrid.width = newGrid.size*newGrid.tileW;
    newGrid.height = newGrid.size*newGrid.tileH;
    
    -- bounding coordinates
    newGrid.minX = cx - newGrid.width*0.5;
    newGrid.maxX = cx + newGrid.width*0.5;
    
    newGrid.minY = cy -  newGrid.height*0.5;
    newGrid.maxY = cy + newGrid.height*0.5;
    
    --newGrid.width = newGrid.maxX - newGrid.minX;
    --newGrid.height = newGrid.maxY - newGrid.minY;
    
    newGrid.originX = newGrid.minX;
    newGrid.originY = cy;--newGrid.minY + 0.5*newGrid.height;
    
    newGrid.centerX = cx;
    newGrid.centerY = cy;
    
    -- tiles center calculations origin, shiftet by (-tileW*0.5,0)
    newGrid.cOriginX = newGrid.minX - newGrid.tileW*0.5;
    
    -- direction vectors, remember coronas graphic system has origin in top left corner!
    newGrid.rightDir = {newGrid.tileW*0.5, newGrid.tileH*0.5}
    newGrid.upDir = {newGrid.tileW*0.5, -newGrid.tileH*0.5}
    
    
    
    return newGrid;
end

-- calculates which coefficients of linear combination of right and up vectors
-- with respects to origin yields x,y, coordinates
-- more precisely solves: (x,y) = a*(rx,ry) + b*(ux,uy) + (ox,oy) for a,b
-- returns a,b calculated cooeficients of linear combination
function IsometricGrid:calcLinComCoeffs(x,y)
    -- lets look at the given x,y coordinates in cartessian space as linear combination
    -- of right and up isometric space generator vectors translated by origin position vector
    -- then constants of linar conbination a,b can be calulated as follows
    
    local a,b;
    local rx = self.rightDir[1];
    local ry = self.rightDir[2];
    local ux = self.upDir[1];
    local uy = self.upDir[2];
    local ox = self.originX;
    local oy = self.originY;
    
    b = (-rx*y+ry*x-ry*ox+oy*rx)/(ry*ux-uy*rx);
    a = (x-b*ux-ox)/(rx);
    
    return a,b;
end

-- transforms given [x,y] cartessian coordinates to tile [right,up] indexes 
-- coordinates out of map are reported as -1,-1
function IsometricGrid:cartToIso(x,y)
    
    
    local a,b = self:calcLinComCoeffs(x,y);
    
    
    -- ceil a,b to make them indices
    a = ceil(a);
    b = ceil(b);
    
    if(a > self.size or b > self.size) then -- out of map
        return -1,-1;
    end
    
    return a,b;
    
end

-- transforms given tile [right,up] indexes to cartessian [x,y] tile center coordinates   
-- tile indexes [right,up] are 1 based
-- coordinates out of map are reported as -1,-1
function IsometricGrid:isoToCart(right,up)
    local x,y;
    
    
    x = self.cOriginX + self.rightDir[1]*right + self.upDir[1]*up;
    y = self.originY + self.rightDir[2]*right + self.upDir[2]*up;
    
    
    if(x > self.maxX or y > self.maxY) then
        x =  -1;
        y = -1;
    end
    
    
    return x,y;
end


-- transforms given [x,y] cartessian coordinates to node [right,up] indexes 
-- nodes indexes [right,up] are 1 based
-- coordinates out of map are reported as -1,-1
function IsometricGrid:nodeCartToIso(x,y)
    -- lets look at the given x,y coordinates in cartessian space as linear combination
    -- of right and up isometric space generator vectors translated by origin position vector
    -- then constants of linar conbination a,b can be calulated as follows
    
    local a,b = self:calcLinComCoeffs(x,y);
    
    -- above the []
    --print("a: " .. a .. ", b : " .. b)
    
    -- round a,b  and shift them by 1 to make them indices
    a = round(a)+1;
    b = round(b)+1;
    
    if(a > self.size+1 or b > self.size+1) then -- out of map
        return -1,-1;
    end
    
    return a,b;
end

-- transforms given node [right,up] indexes to cartessian [x,y] tile center coordinates   
-- nodes indexes [right,up] are 1 based
-- coordinates out of map are reported as -1,-1
function IsometricGrid:nodeIsoToCart(right,up)
    
    local x,y;
    right = right -1;
    up = up -1;
    
    x = self.originX + self.rightDir[1]*right + self.upDir[1]*up;
    y = self.originY + self.rightDir[2]*right + self.upDir[2]*up;
    
    
    if(x > self.maxX or y > self.maxY) then
        x =  -1;
        y = -1;
    end
    
    
    return x,y;
    
end


-- transforms given [x,y] cartessian coordinates to edge ["right"/"up", index] coordinates 
-- edge indexes has two compnents:
---- "right"/"up" - edges pointing in right left direction/edges pointing with down up direction
---- intex - index of edge in its "right"/"up" category, counting starts at origin
-- coordinates out of map are reported as "none",-1
function IsometricGrid:edgeCartToIso(x,y)
    
    local a,b = self:calcLinComCoeffs(x,y);
    
    -- separate int and float part of coefficients
    local ri,rf = modf(a);
    local ui,uf = modf(b);
    
    -- now consider space created by these uf, rf float parts
    -- calulate position of uf, rf towards line defined by [0,0], [1,1] points
    local up = false;
    if(uf>rf) then
        up = true;
    end

    -- calulate position of af, bf towards line defined by [0,1], [1,0] points
    local right = false;
    if(rf+uf-1 >0) then
        right = true;
    end
    
    local edgeType;
    
    --print("uf, rf = " .. uf .. ", " .. rf)
    --print("up, right = " .. tostring(up) .. ", " .. tostring(right))
    
    if(up and right) then -- upper right edge
        edgeType= "right";
        ui =  ui+1;
    elseif(up and not right) then -- upper up edge
        edgeType= "up";
    elseif(not up and right) then -- lower up edge
        edgeType= "up";
        ri = ri+1;
    else--if(not up and not right) then -- lower right edge
        edgeType= "right";
    end
    
    -- now the edge type and ri, ui defines edge positively
    -- edge index can be calculated as follows
    local index;
    
    if(edgeType=="up") then
        index = self.size*ri+ui+1;
    else
        index = self.size*ui+ri+1;
    end
    
    if(index > self.size*(self.size+1)) then
        return "none", -1;
    end
    
    return edgeType, index;
end

-- transforms given edge [edgeType,index] indexes to cartessian [x,y] edge center coordinates   
-- nodes index is 1 based and cannot be bigger then size*(size+1)
-- coordinates out of map are reported as -1,-1
function IsometricGrid:edgeIsoToCart(edgeType,index)
    local ri, ui,x,y;
    
    
    if(edgeType == "up") then
        ui = (index-1) % self.size;
        ri = (index-ui-1) / self.size;
        -- shift to center
        ui=ui+0.5;
    elseif(edgeType == "right") then
        ri = (index-1) % self.size;
        ui = (index-ri-1) / self.size;
        -- shift to center
        ri=ri+0.5;
    else
        error(" unsupported edge type: " ..  edgeType)
    end
    
    --print("ri, ui :" .. ri .. ", " .. ui);
    
    x = self.originX + self.rightDir[1]*ri + self.upDir[1]*ui;
    y = self.originY + self.rightDir[2]*ri + self.upDir[2]*ui;
    
    if(x > self.maxX or y > self.maxY) then
        x =  -1;
        y = -1;
    end
    
    return x,y;
end

-- transforms given node [right,up] indexes to cartessian [x,y] tile center coordinates   
-- nodes indexes [right,up] are 1 based
-- coordinates out of map are reported as -1,-1
--[[
function IsometricGrid:edgeIsoToCart(edgeType,right,up)
    error("not implemented yet")
end
]]

-- transforms given [x,y] cartessian coordinates to closest edge/node/tile (and??) indexes 
-- returns all closest edge/node/tile ???? nebo jen jeden ?
-- coordinates out of map are reported as -1,-1
function IsometricGrid:closestCartToIso(right,up)
    error("not implemented yet")
end


-- travreses tiles in correct up-to-down, left-to-right rendering order
-- and call given tileRenderingFunction with tile indexes and cartesian coordinates
-- tileActiobnFcn four paramteres function (right, up, x, y)
-- where:
--- right, up are indexes of tile
--- x,y are cartesian coordinate of tile center
function IsometricGrid:traverseTilesInRenderingOrder(tileActiobnFcn)
    -- row = up
    -- column = row
    
    
    -- right, up indices need to be traversed in diagonal direction
    
    
    local sRight; -- starting column of each slice
    local sUp; -- starting row of each slice
    local diagL; -- diagonal length
    local x,y,r,u;
    
    
    local size = self.size;
    sRight = 1;
    for slice = 1, 2 * size - 1 do
    	--print("diag : " .. slice);
        
        if(slice>=size) then
            sRight = slice - size +1;
            diagL = diagL-1;
        end
        
        if(slice <= size) then
            sUp = size - slice +1;
            diagL = slice;
        end
        
        
        --print("sRight: " .. sRight)
        --print("sUp: " .. sUp)
        --print("diag length " .. diagL)
        
    	for  n = 0, diagL-1 do
            --print( "r: " .. sRight+n .. ", u: " .. sUp+n);
            r = sRight + n;
            u = sUp + n;
            x,y = self:isoToCart(r,u);
            tileActiobnFcn(r,u,x,y);
    	end
    	
    end  
    
end

-- travrse all grid lines from origin to right, and from down to up 
-- and call given tileRenderingFunction with tile indexes and cartesian coordinates
-- gridLineActionFcn four paramteres function (x1, y1, x2, y2) defining grid line
function IsometricGrid:traverseGridLines(gridLineActionFcn)
    
    local x1,x2,y1,y2;
    local rDir = self.rightDir;
    local uDir = self.upDir;
    local size = self.size;
    local oX = self.originX;
    local oY = self.originY;
    
    local aX = uDir[1]*size;
    local aY = uDir[2]*size;
    local bX = rDir[1]*size;
    local bY = rDir[2]*size;
    
    for i=0, size do
        
        -- do down up lines
        x1 = oX + rDir[1]*i;-- + uDir[1]*0;
        y1 = oY + rDir[2]*i;-- + uDir[2]*0;
        
        x2 = oX + rDir[1]*i + aX;
        y2 = oY + rDir[2]*i + aY;
        
        gridLineActionFcn(x1,y1,x2,y2);
        
        -- do left right lines
        x1 = oX + uDir[1]*i;-- + uDir[1]*0;
        y1 = oY + uDir[2]*i;-- + uDir[2]*0;
        
        x2 = oX + bX + uDir[1]*i;
        y2 = oY + bY + uDir[2]*i;
        
        gridLineActionFcn(x1,y1,x2,y2);
    end
    
end

-- travreses edges in correct up-to-down, left-to-right rendering order
-- and call given edgeActiobnFcn with tile indexes and cartesian coordinates
-- tileActiobnFcn four paramteres function (edgeType, index, x, y)
-- where:
--- edgeType id either "right" or "up"
--- index in edge index
--- x,y are cartesian coordinate of edge center
function IsometricGrid:traverseEdgesInRenderingOrder(edgeActiobnFcn)
    -- row = up
    -- column = row
    
    
    -- right, up indices need to be traversed in diagonal direction
    
    
    local sRight; -- starting column of each slice
    local sUp; -- starting row of each slice
    local diagL; -- diagonal length
    local x,y,r,u,edgeType, index; -- r,u coordinates of coresponding tile
    
    
    local size = self.size;
    sRight = 1;
    for slice = 1, 2 * size - 1 do
    	--print("diag : " .. slice);
        
        if(slice>=size) then
            sRight = slice - size +1;
            diagL = diagL-1;
        end
        
        if(slice <= size) then
            sUp = size - slice +1;
            diagL = slice;
        end
        
        
        --print("sRight: " .. sRight)
        --print("sUp: " .. sUp)
        --print("diag length " .. diagL)
        
    	for  n = 0, diagL-1 do
            --print( "r: " .. sRight+n .. ", u: " .. sUp+n);
            r = sRight + n; -- coresponding tile right coordinate
            u = sUp + n; -- coresponding tile up coordinate
            x,y = self:isoToCart(r,u);
            -- determine up and right edges around given tile
            
            -- left up edge
            index = size*(r-1)+u;
            x,y = self:edgeIsoToCart("up",index)
            edgeActiobnFcn("up", index, x,y)
            
            -- up right edge
            index = size*u+r;
            x,y = self:edgeIsoToCart("right",index)
            edgeActiobnFcn("right", index, x,y)
            
            -- down right edge
            if(u==1) then -- we are on map edge
                index = r;
                x,y = self:edgeIsoToCart("right",index)
                edgeActiobnFcn("right", index, x,y)
            end
            
            -- down up edge
            if(r==size) then -- we are on map edge
                index = size*r+u;
            x,y = self:edgeIsoToCart("up",index)
            edgeActiobnFcn("up", index, x,y)
            end
            
            --edgeActiobnFcn
            -- if border tile 
            --edgeActiobnFcn
            --edgeActiobnFcn
            --tileActiobnFcn(r,u,x,y);
    	end
    	
    end  
    
end



return IsometricGrid;


local geometry ={};
local abs = math.abs;
local max = math.max;

-- movement in grid directions definition
-- eight directions coordinates changes
-- ur, dr, dl, ul, right, down, left, up
geometry.eightDir = {{0,1},{1,0},{0,-1},{-1,0},{1,1},{1,-1},{-1,-1},{-1,1}}
-- four directions coordineres changes
-- ur, dr, dl, ul
geometry.fourDir = {{0,1},{1,0},{0,-1},{-1,0}}


--return direction number
-- dx,dy - Position change. dx,dy can be 0,1  or -1 other values will return undefined results
function geometry.getDirNum(dr,du)
    
    if(dr == -1) then
        if(du == -1) then -- left
            return 7;
        elseif(du== 0) then -- ul
            return 4;
        else -- du == 1, up
            return 8;
        end
    elseif(dr== 0) then
        if(du == -1) then -- dl
            return 3;
        elseif(du== 0) then
            return 0; -- no direction
        else -- du == 1, ur
            return 1;
        end
    else -- dr == 1
        if(du == -1) then -- down
            return 6;
        elseif(du== 0) then -- dr
            return 2;
        else -- du == 1, right
            return 5;
        end
    end
    
    return 0;
    
end


function geometry.eucleidDist( x1, y1, x2, y2 )
    local xFactor = x2 - x1
    local yFactor = y2 - y1
    local dist = math.sqrt( (xFactor*xFactor) + (yFactor*yFactor) )
    return dist
end

function geometry.manhattanDist( x1, y1, x2, y2 )
    return abs(x2 - x1) + abs(y2 - y1);
end

function geometry.chebyshevDist( x1, y1, x2, y2 )
    return max(abs(x2 - x1),abs(y2 - y1));
end

-- search grid in spiral pattern 
-- spiral_search(sx,sy,maxDist, ifGoalFun), where:
---- sx,sy - start coordinates
---- maxDist - maximal manhattan search distance (max spiral diameter)
---- inGoalFun(x,y) -- function returning true when search goal is reached, false otherwise
function geometry.spiral_search(sx,sy,maxDist, inGoalFun)
    error("geometry.spiral_search not supported yet")
    --see: http://stackoverflow.com/questions/398299/looping-in-a-spiral
    --[[
    local x,y,dx,dy;
    x, y, dx =0,0,0;
    dy = -1;
    local t = math.max(sx,sy);
    local maxI = t*t;
    for  i =0, maxI, 1 do
        if ((-sx/2 <= x) and (x <= sx/2) and (-sy/2 <= y) and (y <= sy/2)) then
            --// DO STUFF...
            print("x,y: " .. x .. ", " .. y);
        end
        if( (x == y) || ((x < 0) && (x == -y)) || ((x > 0) && (x == 1-y)))then
            t = dx;
            dx = -dy;
            dy = t;
        end
        x += dx;
        y += dy;
    end
    ]]
end

return geometry;


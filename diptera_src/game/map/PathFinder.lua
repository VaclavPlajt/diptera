

local PathFinder = {}


-- some of possible heuristics
--local heur = function(a,b,c,d) return distFun(a,b,c,d)*1.0001; end; 
--local heur = function(a,b,c,d) return 0; end;
    --[[
    local heur = 
    function(cr,cu,gr,gu)
        local dr1 = cr - gr;
        local dr2 = sr - gr;
        
        local du1 = cu - gu;
        local du2 = su - gu;
        
        local cross = math.abs(dr1*du2 - dr2*du1);
        
        return distFun(cr,cu,gr,gu)+cross*0.001; 
    end; 
]]


function PathFinder:new(condensatePaths)
    
    local newPathFinder = {};
    
    setmetatable(newPathFinder, self);
    self.__index = self;
    
    -- distance masuring function
    local geometryMath = require("math.geometry"); 
    local distFun = geometryMath.manhattanDist;
    
    
    newPathFinder.directions = geometryMath.eightDir;
    newPathFinder.heuristics = distFun;
    newPathFinder.condensatePaths = condensatePaths or false;
    
    -- map of open nodes, quick member test
    newPathFinder.openMap = require("datastructures.Map2D"):new(); 
    -- priority queue of open nodes
    newPathFinder.openQueue =  require("datastructures.BinaryHeap"):new(); -- open nodes priority queue, priority is a cost fo far
    
    -- map of closed nodes, quick member test
    newPathFinder.closedMap = require("datastructures.Map2D"):new();
    
    return newPathFinder;
end

-- purge previous data 
function PathFinder:clear()
    self.openQueue:clear();
    self.openMap:clear();
    self.closedMap:clear();
end

-- pathFinder:findPath(sr,su,gr,gu,acessibilityFun, debug)
-- heuristic (possibly A*) search
-- refer to: http://theory.stanford.edu/~amitp/GameProgramming/ImplementationNotes.html
-- returns path from node [su,sr] to [gr,gu]
-- parameters:
--  sr, su - coordainates of start node
--  gr gu - coordinates of goal node
--  acessibilityFun(r,u,cr,cu) - Function returninig true when tile on r,u coordinates is accessible.  cr,cu are current (source) tile coordinate
--  isInGoalFun(currentNodeData) - optional, function returning true when goal is reached, supply null if not function of your own
--  debugInfo - optional parameter, if given functin will also returns debug information
--
-- the path is returned as a list with item defined as {nr,nu,pr,pu,g,h} where:
-- [1,2]: nr, nu - node right and up coordinates
-- [3,4]: pr, pu - parent (previous node on path) coordinates
-- [5]:   g - g(n) - cost of path from goal to given node
-- [6]:   h - h(n, goal) value of heuristic function
-- [7]:   parent to this node movement direction code
function PathFinder:findPath(sr,su,gr,gu,acessibilityFun, isInGoalFun, debugInfo)
    
    self:clear();
    
    local openQueue = self.openQueue;
    local openMap = self.openMap;
    local closedMap = self.closedMap;
    local dir = self.directions;
    local heur = self.heuristics; 
    local visitedNodes = 0;
    local rememberedNodes = 0;
    local expandedNodes = 0;
    local isGoal = isInGoalFun or function(nodeData) return (nodeData[1] == gr and nodeData[2] == gu)  end;
    
    -- current node data
    local cNode = {sr,su,sr,su,0,heur(sr,su,gr,gu),0}; 
    
    -- add start node to open queue and map
    openMap:add(cNode[1],cNode[2], cNode ); 
    openQueue:insert(cNode[5]+cNode[6],cNode);
    
    local cr, cu; -- current expanding node coordinates
    
    local costSoFar;
    
    while(not isGoal(cNode)) do -- while goal is not reached
        
        -- retrieve lowest ranked node from open queue
        costSoFar, cNode  = openQueue:delMin();
        
        if(cNode == nil) then
            --print("path not found !")
            break;
        end
        
        cr = cNode[1]; cu = cNode[2];
        -- remove current from open map
        openMap:remove(cr,cu);
        -- add current to closed
        closedMap:add(cr,cu,cNode);
        
        -- expand current node
        expandedNodes = expandedNodes +1;
        local cost = cNode[5] + 1; -- cost of reaching neighbor
        local neighbor; -- neighbor node
        local nr, nu; -- currend neighbor coordinates
        for i=1,#dir do -- for each possible movement direction
            nr = cr + dir[i][1]; nu = cu + dir[i][2];  -- neighbor coordinates
            
            -- if neighbor is accesible
            if(acessibilityFun(nr,nu,cr,cu)) then 
                --if(nu > 0 and nu <= size and nr >0 and nr <= size) then 
                visitedNodes = visitedNodes+1;
                
                neighbor = openMap:get(nr,nu);
                if( neighbor and  cost < neighbor[5] ) then -- neighbor in OPEN and cost less than previous reach cost
                    -- new path is better, so change priority in open queue
                    --openMap:remove(nr, nu);
                    local oldCost = neighbor[5];
                    neighbor[5] = cost; -- set new cost
                    neighbor[3] = cr; -- set new parent
                    neighbor[4] = cu;
                    neighbor[7] = i; -- direction code
                    openQueue:changeKey(oldCost ,neighbor, cost+neighbor[6])
                end
                
                neighbor = closedMap:get(nr,nu);
                if( neighbor and cost < neighbor[5] ) then --  neighbor in CLOSED and cost less than g(neighbor)
                    --print("warning: inadmissible heuristics ??");
                    closedMap:remove(nr,nu);
                    neighbor = nil;
                end
                
                if(openMap:get(nr,nu) == nil and neighbor == nil) then -- neighbor not in OPEN and neighbor not in CLOSED
                    rememberedNodes =rememberedNodes +1;
                    
                    local h = heur(nr,nu, gr,gu);
                    neighbor = {nr, nu,cr,cu,cost,h, i};
                    
                    -- add neighbor to open map and open priority queue
                    openMap:add(nr,nu, neighbor ); 
                    openQueue:insert(cost+h,neighbor);
                end    
            end
        end
    end
    
    
    local path=nil;
    if(cNode) then
        path = self:reconstructPath(cNode, sr, su);
    end
    
    if(debugInfo) then
        local info = {
            openMap=openMap,
            closedMap=closedMap,
            visitedNodes= visitedNodes,
            rememberedNodes=rememberedNodes,
            expandedNodes = expandedNodes,
        };
        
        if(path) then
            info.pathCost = path[#path][5];
        end
        
        return path,info;
    else
        return path; 
    end
    
end

function PathFinder:reconstructPath(goalNodeData, sr, su)
    -- reconstruct reverse path from goal to start by following parent pointers
    local reversePath = {};
    local closedMap = self.closedMap;
    
    while(not (goalNodeData[1] == sr and goalNodeData[2] == su)) do
        reversePath[#reversePath+1] = goalNodeData;
        
        -- get parent from closed map
        goalNodeData = closedMap:get(goalNodeData[3], goalNodeData[4]); 
    end
    
    reversePath[#reversePath+1] = goalNodeData;
    
    
    
    local prevDir, currDir = 0,0;
    local path = {};
    
    
    if(self.condensatePaths) then -- condensated path
        for i = #reversePath, 1, -1 do
                        
            currDir = reversePath[i][7];
            
            -- add previous node node to when direction change, except the first one
            if(currDir ~= prevDir and i+1 < #reversePath) then     
                path[#path+1] = reversePath[i+1]; -- countin backwards so +1 not -1
            end
            
            -- last and first points of path belongs to condensated path
            if(i == #reversePath or i == 1) then
                path[#path+1] = reversePath[i];
            end
            
            prevDir = currDir;
            
        end
        
        
        
    else -- full path
        for i = #reversePath, 1, -1 do
            path[#reversePath-i+1] = reversePath[i]; 
        end
    end
    
    return path;
end







return PathFinder;


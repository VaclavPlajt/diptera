-- minion itself does not have any controll of its behavior it is controlled by simple commands from minionController


local Minion = {}


setmetatable(Minion, require("game.unit.Unit"))
Minion.__index = Minion

local abs = math.abs;
local rnd = math.random;

local showPaths = false; -- show debug path graphics


--local geometryMath = require("math.geometry"); 
--local distFun = geometryMath.manhattanDist;
    
--local directions = require("math.geometry").eightDir;

function Minion:new(r,u,isoGrid)
    local newMinion = require("game.unit.Unit"):new("Minion");
    
    -- set meta tables so lookups will work
    setmetatable(newMinion, self)
    self.__index = self
    
    newMinion:init(r,u, isoGrid);
    
    self.graphics = nil;
    
    
    newMinion:dispatchUnitCreatedEvent(r,u);
    
    return newMinion;
end

function Minion:initGraphics(x,y,layer,aboveMapLayer, img)
    self.graphics = require("game.unit.MinionGraphics"):new(x,y,layer, aboveMapLayer, img,self.isoGrid, self);
end

function Minion:init(r,u, isoGrid)
    local gameConst = require("game.gameConst");
    self.movementSpeed = gameConst.minionMovementSpeed;
    
    self.r = r;
    self.u = u;
    self.isoGrid = isoGrid;
    self.dir =0; -- movement direction, 0 = no movement
    self.movementDelay = rnd(0, 250); --delay before mnovement starts in ms
    self.path = nil;
    self.pathIndex = 0;
    
    -- task variables
    self.taskState = "idle";
    self.taskData = nil;
    self.taskTimer = nil;
    self.request = nil;
    
    
end

-- gr, gu - optional parameter of goal/target item coordinates bounded to task minion is doing
function Minion:setTaskState(state, gr, gu)
    self.taskState = state;
    
    self.graphics:setWorkingCoord(gr,gu);
    
    --self.graphics:update(); -- directiion ???
end

function Minion:setToIdle()
    self:cancelMove();
    --self.taskState = "idle";
    self:setTaskState("idle");
    self.taskData = nil;
    
    if(self.taskTimer) then
        timer.cancel(self.taskTimer);
    end
    
    self.taskTimer = nil;
    self.request = nil;
    self.graphics:update();
end

function Minion:isIdle()
    return self.taskState == "idle";
end

-- returns right, up isometric coordinates
function Minion:getIsoCoord()
    if(self.r and self.u) then
        return self.r, self.u;
    else
        return self.isoGrid:cartToIso(self.graphics:getCoord());
    end
end


-- returns x, y cartesian coordinates
function Minion:getCartCoord()
    return self.graphics:getCoord();
end

local function doSegmentMove(minion)
    
    local path = minion.path;
    
    -- movement canceled
    if(path == nil) then
        minion:cancelMove();
        return;
    end
    
    local pathIndex = minion.pathIndex;
    
    if(pathIndex >= #path) then -- if #path == 1, then there is no time to show minion image with transported item!
        minion:endMove();
        return;
    end
    
    
    local currentNode = path[pathIndex];
    local nextNode = path[pathIndex+1];
    -- calc manhattan distance in tiles
    local dist =  abs(nextNode[1] - currentNode[1]) + abs(nextNode[2] - currentNode[2]);
    local time = dist / minion.movementSpeed*1000;
    
    local x,y = minion.isoGrid:isoToCart(nextNode[1], nextNode[2]);
    
    local delay;
    if(pathIndex == 1) then
        delay = minion.movementDelay;
    else
        delay = 0;
    end
    
    -- set direction
    local dirNum = nextNode[7]; -- determined by pathfinder
    --if(dirNum) then
        --print("dir Num: " ..dirNum )
    --minion.graphics:changeDirection(directions[dirNum], dirNum)
    minion.graphics:updateDirectionImage(dirNum);
    --end
    
    minion.graphics:translate(x,y,time,delay,
    function()
        minion.pathIndex =  pathIndex + 1;
        doSegmentMove(minion);
    end
    )
    
end

-- minion will move along the given path
function Minion:move(path, callback)
    --print("#path: " .. #path)
    
    self.path = path;
    self.pathIndex = 1;
    -- invalidate iso grid coordinates
    self.r = nil;
    self.u = nil;
    self.pathEndCallback = callback;
    
    
    if(path and showPaths) then
        self.graphics:showPath(path);
    end
    
    doSegmentMove(self);
    
end

function Minion:cancelMove()
    self.path = nil;
    self.pathIndex = 0;
    self.pathEndCallback = nil;
    self.graphics:cancelTranslation();
    self.r, self.u = self:getIsoCoord();
    --print("move cancelled, r,u:" .. self.r .. "," .. self.u)
end

function Minion:endMove()
    --self.state = "idle";
    self.path = nil;
    self.pathIndex = 0;
    self.r, self.u = self:getIsoCoord();
    self.graphics.translation = nil;
    
    if(self.pathEndCallback) then
        self.pathEndCallback();
        self.pathEndCallback = nil;
    end
    
end


function Minion:setWorkType(workType)
    self.graphics:setWorkType(workType)
end


-- sets minion state to iddle and teleport it to given tile coord
function Minion:forcePosition(r,u)
    self:setToIdle(); -- cancels move
    
    self.r = r; self.u = u;
    
    local x,y = self.isoGrid:isoToCart(r, u);
    
    self.graphics:forcePosision(x,y);
end

function Minion:assignToRequest(r)
    self.request = r;
end

return Minion;


-- damage delivering unit
-- one shot only
-- travels along given path to target

local Missile = {}


setmetatable(Missile, require("game.unit.Unit"));
Missile.__index = Missile;

local abs = math.abs;


function Missile:new(r,u,gr,gu,isoGrid, damage, onTargetReached)
    local newMissile = require("game.unit.Unit"):new("Missile");
    
    -- set meta tables so lookups will work
    setmetatable(newMissile, self)
    self.__index = self
    
    local gameConst = require("game.gameConst");
    
    
    newMissile.isoGrid = isoGrid;
    newMissile.pathIndex = 0;
    newMissile.r = r;
    newMissile.u = u;
    newMissile.gr = gr;
    newMissile.gu = gu;
    newMissile.damage = damage;
    newMissile.onTargetReached = onTargetReached;
    newMissile.movTransition = nil;
    newMissile.rotTransition = nil;
    newMissile.movementSpeed = gameConst.missile.movementSpeed;
    
    
    --newMissile:move();
    newMissile:dispatchUnitCreatedEvent(r,u);
    
    
    
    return newMissile;
end



function Missile:initGraphics(x,y,layer, img, mapDebugLayer)
    
    local g = display.newGroup();
    layer:insert(g);
    self.g = g;
    
    g.x = x;
    g.y =y;
    
    local filePath = "missile.png";
    
    
    self.dispObj = img:newTileImg{w=80, h=80, dir= "gun", name=filePath, group=g, cx=0, cy = 0}
    
    if(mapDebugLayer) then
        self.label = display.newText("" .. self.damage, 0, 0, native.systemFont, 14 )
        mapDebugLayer:insert(self.label);
    end
    
    -- play sound
    local contX,contY = layer:localToContent(x, y);
    Runtime:dispatchEvent({name="soundrequest", type="playnammed", soundName="missle_launch", x=contX, y=contY});
    
end

local function doDescRot(missile)
    missile.rot = -missile.rot;
    missile.rotTransition = transition.to(missile.dispObj, {rotation=missile.rot, time=450, onComplete =
        function()
                doDescRot(missile);
        end
    });
end

local function doSegmentMove(missile)
    
    local pathIndex = missile.pathIndex;
    
    if(pathIndex == 1) then -- move up 
        
        
        missile.movTransition = transition.to(missile.g, {x=missile.topX,y=missile.topY, time=missile.ascentTime, transition = easing.outCubic, onComplete =
            function()
                missile.pathIndex =  pathIndex + 1;
                doSegmentMove(missile);
            end
        });
        
        
    elseif(pathIndex == 2) then -- descent to the target
        
        missile.movTransition = transition.to(missile.g, {x=missile.gx,y=missile.gy, time=missile.descentTime,transition = easing.inCubic, onComplete =
            function()
                missile.pathIndex =  pathIndex + 1;
                doSegmentMove(missile);
            end
        });
        
        missile.rot = 30;
        doDescRot(missile);
        
    elseif(pathIndex >= 3) then
        missile:endMove();
        return;
    end
    
end



-- minion will move along the given path
function Missile:move()
    
    -- calc movement params
    local isoGrid = self.isoGrid;
    local r,u = self.r, self.u;
    local gr,gu = self.gr, self.gu;
    local dist =  abs(r - gr) + abs(u - gu);
    --print("missile r,u:" .. r .. ", " .. u)
    --print("missile gr,gu:" .. gr .. ", " .. gu)
    local time = dist / self.movementSpeed*1000;
    --print("missile time:" .. time)
    self.ascentTime = time * 0.2;
    self.descentTime = time - self.ascentTime;
    local gx,gy = isoGrid:isoToCart(gr, gu);
    self.gx = gx; self.gy = gy;
    local x,y = isoGrid:isoToCart(r, u);
    --self.x = x; self.y = y;
    local topHeight = isoGrid.tileH * 5;
    self.topX = x;--0.5*(x+gx);
    self.topY = y - topHeight;

    
    self.pathIndex = 1;        
    doSegmentMove(self);
end

function Missile:endMove()
    --self.state = "idle";
    if(self.onTargetReached) then
        self.onTargetReached();
    end
    
    
    self:destroy();
end

function Missile:destroy()
    
    self.path = nil;
    self.pathIndex = 0;
    
    if(self.movTransition) then
        transition.cancel(self.movTransition);
        self.movTransition = nil;
    end
    
    if(self.rotTransition) then
        transition.cancel(self.rotTransition);
        self.rotTransition = nil;
    end
    
    self.g:removeSelf();
    --self.dispObj:removeSelf();  
    --self.label:removeSelf();
    self:dispatchUnitDestroyedEvent();
end

return Missile;




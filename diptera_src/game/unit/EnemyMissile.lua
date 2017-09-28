-- damage delivering unit
-- one shot only
-- travels along given path to target

local EnemyMissile = {}


setmetatable(EnemyMissile, require("game.unit.Unit"));
EnemyMissile.__index = EnemyMissile;

local abs = math.abs;


function EnemyMissile:new(r,u,path,isoGrid, damage,onTargetReached)
    local newMissile = require("game.unit.Unit"):new("EnemyMissile");
    
    -- set meta tables so lookups will work
    setmetatable(newMissile, self)
    self.__index = self
    
    local gameConst = require("game.gameConst");
    
    
    newMissile.isoGrid = isoGrid;
    newMissile.pathIndex = 0;
    newMissile.path = path;
    newMissile.damage = damage;
    newMissile.aiMissile = true;
    newMissile.onTargetReached = onTargetReached;
    newMissile.movTransition = nil;
    
    newMissile.movementSpeed = gameConst.AIParams.enemyMissileMovementSpeed;
    newMissile.lastImgName = nil;
    
    
    --newMissile:move();
    newMissile:dispatchUnitCreatedEvent(r,u);
    
    return newMissile;
end



function EnemyMissile:initGraphics(x,y,layer, aboveLayer, img, unitDebugLayer)
    self.img =img;
    self.layer = layer;
    self.aboveLayer = aboveLayer;
    
    local g = display.newGroup();
    
    --move first position upwards to be better seen on enemy keeps
    y = y-40;
    
    aboveLayer:insert(g);
    self.g = g;
    self.dispObj = g;
    
    g.x = x;
    g.y =y;
    
    --local startNode = self.path[1];
    self:updateDirectionImage(6);
    
    -- add shadow
    self.shadow = self.img:newTileImg{w=32, h=32, dir= "comm", name="shadow.png", group=g, cx=0, cy = 32}
    
    -- add damage counters
    local size = 3;
    local xC = -(2*size* math.floor(self.damage/2));
    local yC = 20;
    local circ;
    
    for i=1,self.damage do
        circ = display.newCircle(g, xC, yC, size)
        circ:setFillColor(0,0,0,1);
        xC = xC + 2*size;
    end
    
    g.alpha = 0;
    
end


local function doSegmentMove(missile)
    
    local pathIndex = missile.pathIndex;
    local path = missile.path;
    
    --[[
    if(path==nil) then -- missile destroyed somewhat
        return;
    end
    ]]
    
    if(pathIndex >= #path) then
        missile:endMove();
        return;
    end
    
    
    local currentNode = path[pathIndex];
    local nextNode = path[pathIndex+1];
    -- calc manhattan distance in tiles
    local dist =  abs(nextNode[1] - currentNode[1]) + abs(nextNode[2] - currentNode[2]);
    local time = dist / missile.movementSpeed*1000;
    
    local x,y = missile.isoGrid:isoToCart(nextNode[1], nextNode[2]);
    
    missile.movTransition = transition.to(missile.g, {x=x,y=y, time=time, onComplete =
    function()
        missile.pathIndex =  pathIndex + 1;
        doSegmentMove(missile);
    end,
    onCancel = 
    function()
        -- ugly workarround because I cannot trace the source of al transitions cancelation
        --print("EnemyMissile: transition canceled");
        --print(debug.traceback());
        if(missile.path) then doSegmentMove(missile); end
    end,
    --[[onPause = 
    function()
        print("EnemyMissile: transition paused");
    end,]]
    });
    
    missile:updateDirectionImage(nextNode[7]);
end

-- minion will move along the given path
function EnemyMissile:move()
    self.pathIndex = 1;
    
    transition.to(self.g, {alpha=1, time = 1250, transition = easing.inSine , onComplete= 
        function()
            if(self.path) then
                doSegmentMove(self);
                local g = self.g;
                self.layer:insert(g);
                
                -- play sound
                local x,y = g:localToContent(0, 0);
                Runtime:dispatchEvent({name="soundrequest", type="playnammed", soundName="enemy_missile", x=x, y=y});
            end
        end
        });
end

function EnemyMissile:endMove()
    --print("EnemyMissile:endMove()")
    --self.state = "idle";
    self:destroy();
    
    if(self.onTargetReached) then
        self.onTargetReached();
    end

    
    --self:destroy();
end

function EnemyMissile:destroy()
    --print("EnemyMissile:destroy()")
    
    self.path = nil;
    self.pathIndex = 0;
    
    if(self.movTransition) then
        transition.cancel(self.movTransition);
        self.movTransition = nil;
    end
    
    self.g:removeSelf();
    self.g = nil;
    --self.dispObj:removeSelf();  
    --self.label:removeSelf();
    self:dispatchUnitDestroyedEvent();
end

function EnemyMissile:updateDirectionImage(dirNum)
    
    
    -- eight directions coordinates changes
    -- ur, dr, dl, ul, right, down, left, up
    --geometry.eightDir = {{0,1},{1,0},{0,-1},{-1,0},{1,1},{1,-1},{-1,-1},{-1,1}}
    
    local imgName;
    
    if(dirNum == 0) then 
        return; -- noting to change
    elseif(dirNum == 1) then -- ur
        imgName ="enemyMissile_ur.png"
    elseif(dirNum == 2) then -- dr
        imgName ="enemyMissile_dr.png"
    elseif(dirNum == 3) then -- dl
        imgName ="enemyMissile_dl.png"
    elseif(dirNum == 4) then -- ul
        imgName ="enemyMissile_ul.png"
    elseif(dirNum == 5) then -- right
        imgName ="enemyMissile_right.png"
    elseif(dirNum == 6) then -- down 
        imgName ="enemyMissile_down.png"
    elseif(dirNum == 7) then -- left
        imgName ="enemyMissile_left.png"
    elseif(dirNum == 8) then -- up
        imgName ="enemyMissile_up.png"
    else
        print("Warning, EnemyMissile:updateDirectionImage: unsuported direction num:" .. tostring(dirNum));
        return; -- no update can be done
    end
    
    if(self.lastImgName ~= imgName) then
        if(self.image) then self.image:removeSelf() end;
        
        self.image = self.img:newTileImg{w=64, h=32, dir= "enemyMissile", name=imgName, group=self.g, cx=0, cy = 0}
        self.image:toBack();
    end
    
end


return EnemyMissile;






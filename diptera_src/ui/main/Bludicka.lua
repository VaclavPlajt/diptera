

local Bludicka  = {}

local rnd = math.random;
local movemenSpeed = 15; -- content px in second
local distMeasure = require("math.geometry").chebyshevDist;

local easings = {
    easing.linear,
    easing.inSine, easing.outSine, easing.inOutSine, easing.outInSine,
    easing.inQuart, easing.outQuart, easing.inOutQuart, easing.outInQuart
    };


function Bludicka:new(layer, context, minX, minY, maxX, maxY, style)
    
    local newBludicka = {};
    
    setmetatable(newBludicka, self);
    self.__index = self; 
    
    
    newBludicka.layer = layer;
    --newBludicka.uiConst = context.uiConst;
    --newBludicka.bounds = context.displayBounds;
    newBludicka.minX, newBludicka.minY, newBludicka.maxX, newBludicka.maxY = minX, minY, maxX, maxY;
    
    
    newBludicka:init(layer, style);
    
    
    return newBludicka;
end


function Bludicka:init(layer, style)
    
    local size = rnd(8,25);
    if(style) then
        self.img =  display.newImageRect(layer, "img/comm/bludicka.png", size , size);
    else
        self.img =  display.newImageRect(layer, "img/comm/bludicka_b.png", size , size);
    end
    
    self.img.x = rnd(self.minX,self.maxX);
    self.img.y = rnd(self.minY,self.maxY);
    self.img.rotation =  rnd(0,360);
    --self.img.alpha= 0.2;
    --self.img.blendMode = "add";
    
    self:move();
end


function Bludicka:move()
    
    local img = self.img;
    local destX = rnd(self.minX,self.maxX);
    local destY = rnd(self.minY,self.maxY);
    
    local x,y = img.x, img.y
    
    local dist = distMeasure(x,y,destX,destY);
    
    if(dist==0) then
        self:move();
    else
        local time = 1000*(dist / movemenSpeed);
        transition.cancel(img);
        transition.to(img, {x=destX, time=time, transition =  easings[rnd(#easings)],
        onComplete = 
            function()
               self:move(); 
            end
        });
        
        transition.to(img, {y=destY, time=time, transition =  easings[rnd(#easings)]});
        
        --display.newCircle(self.layer, x, y, 5)
        --display.newCircle(self.layer, destX, destY, 5)
        --print("Bludicka move: dist: " .. dist .. ", time: " .. time)
    end
    
end

function Bludicka:destroy()
    if(self.img) then
        transition.cancel(self.img);
        self.img:removeSelf()
        self.img = nil;
    end
end


return Bludicka;


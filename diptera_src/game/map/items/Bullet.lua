
-- endless source of bullets for gun
-- extends mapItem
local Bullet = {};

setmetatable(Bullet, require("game.map.items.MapItem"))
Bullet.__index = Bullet

--Bullet.infoProperties = {}; -- properties to show in infoPanel
Bullet.iconDir = "img/gun/"
Bullet.icon = "bullet.png";

function Bullet:new(r,u,map)
    local newBullet = require("game.map.items.MapItem"):new("Bullet",r, u, map);
    
    -- set meta tables so lookups will work
    setmetatable(newBullet, self)
    self.__index = self
    
    
    newBullet.removed = false;
    
    
    
    -- ugly workarround, bullet is not considered building !!
    Runtime:dispatchEvent{name="buildingCreated", building=newBullet};
    
    return newBullet;
end



function Bullet:initGraphics(x,y,layer, img, mapDebugLayer)
    
    
    self.dispObj = img:newTileImg{w=128, h=128, dir= "gun", name="bullet.png", cx=x, cy = y}
    self:insertToCalcIndex(layer,self.dispObj);
    
end

function Bullet:updateGrahics()
    if(self.removed) then return true; end
    
end


-- takes one bullet  piece out
-- returns true when item was suceccully picked, false otherwise
function Bullet:takeItem()
    return true;
end

function Bullet:addItem()
    -- do nothing
end

function Bullet:removeIfNeeded()
    --do nothing
end

function Bullet:removeIfNeeded()
    if(self.removed) then return; end;
    --[[
    self.map:removeItem(self);
    self.dispObj:removeSelf();
    if(self.label) then  self.label:removeSelf(); end;
    self.removed = true;
    ]]
end


return Bullet;
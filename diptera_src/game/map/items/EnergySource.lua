
-- source of enrgy on map
-- extends mapItem
local EnergySource = {};

setmetatable(EnergySource, require("game.map.items.MapItem"))
EnergySource.__index = EnergySource

print("Warning, EnergySource: is obsolete and should not be used anywhere!")

function EnergySource:new(r,u,power,map)
    local newEnergySource = require("game.map.items.MapItem"):new("EnergySource",r, u, map);
    
    -- set meta tables so lookups will work
    setmetatable(newEnergySource, self)
    self.__index = self
    
    newEnergySource.power = power;
    
    
    return newEnergySource;
end


function EnergySource:initGraphics(x,y,layer, img)
    
    self.dispObj = img:newImg{dir= "mockup", name="energy", group=layer, cx=x, cy = y}
    local myText = display.newText("" .. self.power, x, y, native.systemFont, 14 )
    --myText:setFillColor(0.9,0.3,0.2,1);
    layer:insert(myText);
end


return EnergySource;
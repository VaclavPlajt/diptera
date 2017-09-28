
-- building used to attack enemy teritories
local HomeKeep = {};

setmetatable(HomeKeep, require("game.map.buildings.Building"))
HomeKeep.__index = HomeKeep

HomeKeep.iconDir = "img/keep/"
HomeKeep.icon = "home.png";

function HomeKeep:new(r,u,map)
    --local gameConst = require("game.gameConst");
    
    --local toughness = gameConst.Keep.toughness;
    local newKeep = require("game.map.buildings.Keep"):new(r, u, map,"HomeKeep");
    
    -- set meta tables so lookups will work
    setmetatable(newKeep, self)
    self.__index = self
    
    -- let others know
    newKeep:dispatchBuildingCreatedEvent()
    
    return newKeep;
end


function HomeKeep:initGraphics(x,y,layer, img, mapDebugLayer)
    self.layer = layer;
    local uiConsts = require("ui.uiConst");
    
    self.dispObj = img:newTileImg{w=uiConsts.mapTileWidth, h=uiConsts.mapTileWidth, dir= "keep", name="home.png", cx=x, cy = y}
    self:insertToCalcIndex(self.layer,self.dispObj);
    
    if(mapDebugLayer) then
        self.label = display.newText("" .. self.fitness, x, y, native.systemFont, 14 )
        --myText:setFillColor(0.9,0.3,0.2,1);
        mapDebugLayer:insert(self.label);
    end
end


function HomeKeep:updateGraphics()
    
    if(self.label) then
        self.label.text = tostring(self.fitness);    
    end
    
end


function HomeKeep:destroy()
    if(self.destroyed) then return end;
    self.destroyed = true;
    
    --[[
    self.map:removeItem(self);
    
    self.dispObj:removeSelf();
    self.dispObj = nil;
    self.label:removeSelf();
    self.label = nil;
    ]]
    
    -- main game event, let others know
    Runtime:dispatchEvent{name="keepDestroyed", keep = self}
end


return HomeKeep;










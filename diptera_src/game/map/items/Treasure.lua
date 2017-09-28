
-- source of bonuses in game, have to be unlocked by minions work
-- extends mapItem
local Treasure = {};

setmetatable(Treasure, require("game.map.items.MapItem"))
Treasure.__index = Treasure

--Treasure.infoProperties = {"unlockWorkAmount", "work"}; -- properties to show in infoPanel
Treasure.progressProperty = {name="unlock", max=1, formating="%"} -- property to show in infopanels progress bar

Treasure.iconDir = "img/treasure/"
Treasure.icon = "treasure.png";

function Treasure:new(r,u,map, unlockWorkAmount, treasureName, treasureParams)
    local newTreasure = require("game.map.items.MapItem"):new("Treasure",r, u, map);
    
    -- set meta tables so lookups will work
    setmetatable(newTreasure, self)
    self.__index = self
    
    newTreasure.unlockWorkAmount = unlockWorkAmount;
    newTreasure.treasureName = treasureName; -- treasure effect name
    newTreasure.treasureParams = treasureParams; -- treasure effect parameters
    newTreasure.removed = false;
    newTreasure.work = 0;
    newTreasure.unlock = 0;
    newTreasure.minionWorkRequest = nil;
    
    -- ugly workarround, Treasure is not considered building !!
    Runtime:dispatchEvent{name="buildingCreated", building=newTreasure};
    
    return newTreasure;
end

--[[
function Treasure:onSelection()
    print("TODO COMENT Treasure:onSelection()");
    self:showSelection();
    self:removeSelf();
    self:onTreasureUnlocked();
end
]]

function Treasure:initGraphics(x,y,layer, img, mapDebugLayer)
    
    --self.dispObj = img:newImg{dir= "mockup", name="treasure", group=layer, cx=x, cy = y-32}
    self.dispObj = img:newTileImg{w=128, h=128, dir= "treasure", name="treasure.png", cx=x, cy = y}
    self.x = x;
    self.y = y;
    self.layer = layer;
    self:insertToCalcIndex(layer,self.dispObj);
    
    if(mapDebugLayer) then
        self.label = display.newText("", x, y, native.systemFont, 14 )
    --myText:setFillColor(0.9,0.3,0.2,1);
        mapDebugLayer:insert(self.label);
    end
    
    self:updateGraphics();
end

function Treasure:updateGraphics()
    if(self.label) then
        self.label.text = self.treasureName .. ", ".. self.work .. "/" .. self.unlockWorkAmount;
    end
end

-- called when minions spends enough time building it
function Treasure:onWorkUnitDone()
    if(self.removed) then return; end;
    
    self.work = self.work +1;
    self:updateGraphics();
    
    self.unlock = self.work / self.unlockWorkAmount;
    
    if(self.work == self.unlockWorkAmount) then
        --print("enough work spend to build" .. self.targetBuildingType);
        self:removeSelf();
        self:onTreasureUnlocked();
    else
        -- play sound
        local contX,contY = self.layer:localToContent(self.x, self.y);
        Runtime:dispatchEvent({name="soundrequest", type="playnammed", soundName="work", x=contX, y=contY});
    end
    
end

function Treasure:cancelWorkRequest()
    if(not self.minionWorkRequest) then return; end;
    
    self.minionWorkRequest.state = "canceled";
    self.minionWorkRequest = nil;
end

function Treasure:sendWorkRequest()
    if(self.minionWorkRequest) then return; end;
    
    --print("enough material to build" .. self.targetBuildingType);
    local request = {
        gr=self.r,gu=self.u,amount=self.unlockWorkAmount - self.work,
        onDelivery = function() self:onWorkUnitDone() end
    }
    
    Runtime:dispatchEvent{name="minionActionRequest", action="work", request = request}
    
    self.minionWorkRequest = request;
end

function Treasure:onTreasureUnlocked()
    -- tell others about unlocked treasure
    Runtime:dispatchEvent{name="treasureUnlocked", treasure=self};
end

function Treasure:removeSelf()
    if(self.removed) then return; end;
    
    self:cancelWorkRequest();
    self.removed = true;
    self.map:removeItem(self);
    self.dispObj:removeSelf();
    if(self.label) then   self.label:removeSelf(); end
end

return Treasure;


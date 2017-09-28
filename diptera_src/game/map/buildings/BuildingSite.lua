
-- base for building process of all other buildings
local BuildingSite = {};

setmetatable(BuildingSite, require("game.map.buildings.Building"))
BuildingSite.__index = BuildingSite

BuildingSite.progressProperty = {name="done", max=1, formating="%"} -- property to show in infopanels progress bar
BuildingSite.iconDir = "img/buildingSite/"
BuildingSite.icon = "BuildingSite_4.png";

function BuildingSite:new(r,u,map, targetBuildingType, minionController)
    local gameConst = require("game.gameConst");
    local buildingType = "BuildingSite";
    local toughness = gameConst[buildingType].toughness;
    local newBuildingSite = require("game.map.buildings.Building"):new(buildingType,r, u, map,toughness);
    
    -- set meta tables so lookups will work
    setmetatable(newBuildingSite, self)
    self.__index = self
    
    
    newBuildingSite.targetBuildingType = targetBuildingType;
    newBuildingSite.minionController = minionController;
    
    local def = gameConst[targetBuildingType];
    
    if(def == nil) then
        error("Undefined building type: " .. targetBuildingType);
    end
    
    newBuildingSite.materialCost = def.materialCost;
    newBuildingSite.material = 0;
    newBuildingSite.workCost = def.workCost;
    newBuildingSite.work = 0;
    newBuildingSite.deconstructonReturnsMaterial = true;
    newBuildingSite.lastImage = nil;
    newBuildingSite.done = 0;
    
    
    local request = {gr=r,gu=u,amount=def.materialCost,itemType="Material",
    onDelivery = function() newBuildingSite:onMaterialDelivery() end}
    
    Runtime:dispatchEvent{name="minionActionRequest", action="transport", request = request}
    
    newBuildingSite.minionActionRequest = request;
    
    -- let others know
    newBuildingSite:dispatchBuildingCreatedEvent();
    
    -- play sound
    Runtime:dispatchEvent({name="soundrequest", type="playnammed", soundName="building_site"});--, x=x, y=y});  
    
    return newBuildingSite;
end


function BuildingSite:initGraphics(x,y,layer, img, mapDebugLayer)
    self.layer = layer;
    self.img = img;
    self.x = x;
    self.y = y;
    --self.dispObj = img:newTileImg{w=128, h=128, dir= "mockup", name="BuildingSite.png", group=layer, cx=x, cy = y}
    self:updateGraphics();
    
    if(mapDebugLayer) then
        self.label = display.newText("", x, y, native.systemFont, 14 )
        mapDebugLayer:insert(self.label);
    end
end

function BuildingSite:updateGraphics()
    if(self.label) then
        self.label.text = "f:" .. self.fitness .. ", M:" .. self.material .. ", W:" .. self.work;
    end
    
    self:updateImage()
    
end

function BuildingSite:updateImage()
    --local lastImg = self.lastImage;
    
    -- selecet image name based on fraction of material delivered to building site
    local matFraction = self.material / self.materialCost;
    local imgName = nil;
    
    if(matFraction <= 0.0)then
        imgName = "BuildingSite_0.png";
    elseif(matFraction < 0.3)then
        imgName = "BuildingSite_1.png";
    elseif(matFraction < 0.6)then
        imgName = "BuildingSite_2.png";
    elseif(matFraction < 1.0)then
        imgName = "BuildingSite_3.png";
    else--if(matFraction < 0.5)then
        imgName = "BuildingSite_4.png";
    end
    
    if(imgName ~= self.lastImage) then
        -- update image
        if(self.dispObj) then self.dispObj:removeSelf(); end;
        
        self.dispObj = self.img:newTileImg{w=128, h=128, dir= "buildingSite", name=imgName, cx=self.x, cy = self.y}--, group=self.layer}
        self:insertToCalcIndex(self.layer,self.dispObj);
        self.lastImage = imgName;
    end
    
end


function BuildingSite:removeGraphics()
    self.dispObj:removeSelf();
    if(self.label ) then   self.label:removeSelf(); end;
end

function BuildingSite:onMaterialDelivery()
    
    if(self.destroyed) then return; end;
    
    self.material = self.material +1;
    
    self:updateGraphics();
    
    -- play sound
    local x,y = self.layer:localToContent(self.x,self.y);
    Runtime:dispatchEvent({name="soundrequest", type="playnammed", soundName="put", x=x, y=y});  
    
    if(self.material == self.materialCost) then
        --print("enough material to build" .. self.targetBuildingType);
        local request = {gr=self.r,gu=self.u,amount=self.workCost,
        onDelivery = function() self:onWorkUnitDone() end}
        
        Runtime:dispatchEvent{name="minionActionRequest", action="work", request = request}
        
        self.minionActionRequest = request;

    end
    
end

-- called when minions spends enough time building it
function BuildingSite:onWorkUnitDone()
    if(self.destroyed) then return; end;
    
    self.work = self.work +1;
    self.done = self.work / self.workCost;
    self:updateGraphics();
    
    if(self.work == self.workCost) then
        --print("enough work spend to build" .. self.targetBuildingType);
        self.map:removeItem(self);
        self:removeGraphics();
        self:createBuilding()  
    else
        -- play sound
        local contX,contY = self.layer:localToContent(self.x, self.y);
        Runtime:dispatchEvent({name="soundrequest", type="playnammed", soundName="work", x=contX, y=contY});
    end
    
    
end

function BuildingSite:createBuilding()
    
    local bType = self.targetBuildingType;
    local building;
    
    if(bType == "Wall") then
        building = require("game.map.buildings.Wall"):new(self.r,self.u,self.map);
    elseif(bType == "Gun") then
        building = require("game.map.buildings.Gun"):new(self.r,self.u,self.map);
    end
    
    
end

--[[
function BuildingSite:deconstruct()
    if(self.inDeconstruction) then return; end
    self.inDeconstruction = true;
        
    -- cancel last send request
    self.minionActionRequest.state = "canceled";
    self:destroy();
    
end
]]

function BuildingSite:destroy()
    if(self.destroyed) then return; end;
    self.destroyed = true;
    
    -- cancel last send request
    if(self.minionActionRequest) then
        self.minionActionRequest.state = "canceled";
    end
    self.map:removeItem(self);
    self.dispObj:removeSelf();
    self.dispObj = nil;
    if(self.label) then self.label:removeSelf(); self.label = nil; end
    
end

return BuildingSite;








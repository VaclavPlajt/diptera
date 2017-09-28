
-- source of enrgy on map
-- extends mapItem
local Material = {};

setmetatable(Material, require("game.map.items.MapItem"))
Material.__index = Material

Material.infoProperties = {"amount"}; -- properties to show in infoPanel

Material.iconDir = "img/material/"
Material.icon = "mat_100.png";

function Material:new(r,u,amount,map)
    local newMaterial = require("game.map.items.MapItem"):new("Material",r, u, map);
    
    -- set meta tables so lookups will work
    setmetatable(newMaterial, self)
    self.__index = self
    
    newMaterial.amount = amount;
    newMaterial.removed = false;
    newMaterial.bringHereRequest = nil;
    newMaterial.lastImgName = nil;
    --newMaterial.bringHereAmount = 0;
    
    -- ugly workarround, material is not considered building !!
    Runtime:dispatchEvent{name="buildingCreated", building=newMaterial};
    
    return newMaterial;
end



function Material:initGraphics(x,y,layer, img, mapDebugLayer)
    self.layer = layer;
    self.img = img;
    self.x = x;
    self.y = y;
    --self.dispObj = img:newImg{dir= "mockup", name="material", group=layer, cx=x, cy = y}
    --self.dispObj = img:newTileImg{w=128, h=128, dir= "mockup", name="material.png", cx=x, cy = y}
    --self:insertToCalcIndex(layer,self.dispObj);
    
    self:updateImage();
    
    if(mapDebugLayer) then
        self.label = display.newText("" .. self.amount, x, y, native.systemFont, 14 )
        --myText:setFillColor(0.9,0.3,0.2,1);
        mapDebugLayer:insert(self.label);
    end
end

function Material:updateGrahics()
    if(self.removed) then return true; end
    
    if(self.label) then
        self.label.text = tostring(self.amount);
    end
    
    self:updateImage();
end


-- takes one material piece out
-- returns true when item was suceccully picked, false otherwise
function Material:takeItem()
    self.amount = self.amount - 1;
    
    if(self.amount < 0) then-- and self.bringHereRequest==nil) then
        self.amount = 0;
        
        if(self.bringHereRequest)then
            self:cancelBringHereRequest();
        end
        
        self:updateGrahics();
        return false;
    else
        self:updateGrahics();
        Runtime:dispatchEvent{name="infoevent", info="matTaken"}
        -- play sound
        --local x,y = self.layer:localToContent(self.x,self.y);
        --Runtime:dispatchEvent({name="soundrequest", type="playnammed", soundName="building_site", x=x, y=y});  
        return true;
    end
    
    
end

function Material:addItem(playSound)
    if(self.removed) then return; end; -- when this happen one pice of material will be lost!
    self.amount = self.amount + 1;
    
    if(self.bringHereRequest and self.bringHereRequest.amount <= 1) then
        self.bringHereRequest = nil;
    end
    
    self:updateGrahics();
    Runtime:dispatchEvent{name="infoevent", info="matAdded"}
    
    if(playSound) then
        -- play sound
        local x,y = self.layer:localToContent(self.x,self.y);
        Runtime:dispatchEvent({name="soundrequest", type="playnammed", soundName="put", x=x, y=y});  
    end
    
end

function Material:removeIfNeeded()
    if(self.removed) then return; end;
    
    if(self.amount <= 0) then
        self.map:removeItem(self);
        self.dispObj:removeSelf();
        if(self.label) then  self.label:removeSelf(); end;
        self.removed = true;
        
        if(self.bringHereRequest) then
            self.bringHereRequest.state = "canceled";
            self.bringHereRequest = nil;
        end
        
    end
end


function Material:cancelBringHereRequest()
    if(self.bringHereRequest) then
        self.bringHereRequest.state = "canceled";
        self:removeIfNeeded(); -- request may be cancalled before first item arrival
        self.bringHereRequest = nil;
    end
end


function Material:updateImage()
    
    local imgNames = {"mat_0.png", "mat_25.png", "mat_50.png", "mat_75.png", "mat_100.png"}
    local maxAmount = 80;
    local ratio = self.amount/maxAmount;
    
    local index = math.ceil((#imgNames-1) *  ratio)+1;
    if(index == 0) then index = 1; end;
    
    if(self.amount > maxAmount) then
        print("Material, Warning: amount bigger then maxAmount. choosing last image:");
        index = #imgNames;
    end
       
    local imgName = imgNames[index];
    
    --print("amount: " .. self.amount .. ", index:" .. index .. ", imgName:" .. imgName);
    
    --[[]
    if(ratio == 0) then 
        imgName ="mat_0.png"
    elseif(ratio <= 1) then -- ur
        imgName =
    elseif(ratio == 2) then -- dr
        imgName ="minion_dr.png"
    elseif(ratio == 3) then -- dl
        imgName ="minion_dl.png"
    elseif(ratio == 4) then -- ul
        imgName ="minion_ul.png"
    elseif(ratio == 5) then -- right
        imgName ="minion_right.png"
    elseif(ratio == 6) then -- down 
        imgName ="minion_down.png"
    elseif(ratio == 7) then -- left
        imgName ="minion_left.png"
    elseif(ratio == 8) then -- up
        imgName ="minion_up.png"
    else
        print("Warning, EnemyMissile:updateDirectionImage: unsuported direction num:" .. tostring(ratio));
        return; -- no update can be done
    end
    --]]
    if(self.lastImgName ~= imgName) then
        if(self.dispObj) then self.dispObj:removeSelf() end;
        
        local layer = self.layer;
        self.dispObj = self.img:newTileImg{w=128, h=128, dir= "material", name=imgName, group=layer, cx=self.x, cy = self.y}
        self:insertToCalcIndex(layer,self.dispObj);
        --self.dispObj:setFillColor(unpack(self.tintColor));
    end
    
end

return Material;
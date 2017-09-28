
-- building used to attack enemy teritories
local Keep = {};

setmetatable(Keep, require("game.map.buildings.Building"))
Keep.__index = Keep

Keep.iconDir = "img/keep/"
Keep.icon= "cat1.png";

--local disSymbolsCount = 5;

function Keep:new(r,u,map, descendantType)
    
    
    local itemType = descendantType or "Keep";
    local toughness;
    local  powerCategory = 0;
    
    if(itemType == "Keep") then
        local clusterNum = map.tiles[r][u].cluster;
        local powerProperties = map.clusters[clusterNum].powerProperties;
        toughness = powerProperties.keepToughness;
        powerCategory = powerProperties.powerCategory;
    else
        local gameConst = require("game.gameConst");
        toughness = gameConst[itemType].toughness;
    end
    
    local newKeep = require("game.map.buildings.Building"):new(itemType,r, u, map,toughness);
    
    -- set meta tables so lookups will work
    setmetatable(newKeep, self)
    self.__index = self
    
    newKeep.powerCategory = powerCategory;
    
    if(itemType == "Keep") then -- descendant types have to do this on their own
        -- let others know
        newKeep:dispatchBuildingCreatedEvent()
    end
    
    return newKeep;
end


function Keep:initGraphics(x,y,layer, img, mapDebugLayer)
    self.layer = layer;
    
    local imgName = "cat" .. self.powerCategory .. ".png";
    --print("keep img: " .. imgName)
    
    self.icon = imgName;
    self.dispObj = img:newTileImg{w=128, h=128, dir= "keep", name=imgName, cx=x, cy = y}
    self:insertToCalcIndex(self.layer,self.dispObj);
    
    if(mapDebugLayer) then
        self.label = display.newText("" .. self.fitness, x, y, native.systemFont, 14 )
        --myText:setFillColor(0.9,0.3,0.2,1);
        mapDebugLayer:insert(self.label);
    end
end


function Keep:updateGraphics()
    
    if(self.label) then
        self.label.text = tostring(self.fitness);    
    end
    
end

function Keep:destroy()
    if(self.destroyed) then return end;
    self.destroyed = true;
    
    self.map:removeItem(self);
    
    self.dispObj:removeSelf();
    self.dispObj = nil;
    if(self.label) then self.label:removeSelf(); self.label = nil; end;
    
    if(self.lastHitEmmiter) then
        self.lastHitEmmiter:removeSelf();
        self.lastHitEmmiter = nil;
    end
    
    -- main game evwnt, let others know
    Runtime:dispatchEvent{name="keepDestroyed", keep = self}
end

--[[ TODO - add disiease symbols to damaged keeps
function Keep:createDisSymbols()
    
    
    -- add regeneration symbols
    local tileW = 
    local rw = tileW*0.5;
    local rdx = regenSymbolsSize+(rw - (regenSymbolsCount*regenSymbolsSize))/(regenSymbolsCount-1);
    local rx = x-rw*0.5+regenSymbolsSize*0.5;
    local ry = y + regenSymbolsYoffset;
    
    for i=1, disSymbolsCount do
        --local symbol = display.newCircle(g, rx, ry, regenSymbolsSize)
        local symbol = display.newImageRect(g, "img/comm/dis_small.png", regenSymbolsSize, regenSymbolsSize)
        symbol.x, symbol.y = rx, ry;
        symbol:setFillColor(0,0,0);
        symbol.alpha = 0.2;
        self.regenSymbols[i] = symbol;
        rx = rx +rdx;
    end
end
]]

return Keep;








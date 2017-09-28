
-- untaken destroyed cluster keep
local DestroyedKeep = {}

setmetatable(DestroyedKeep, require("game.map.buildings.Building"))
DestroyedKeep.__index = DestroyedKeep

--DestroyedKeep.infoProperties = {"regeneration"}; -- properties to show in infoPanel
DestroyedKeep.progressProperty = {name="conversion", max=1, formating="%"} -- property to show in infopanels progress bar


DestroyedKeep.iconDir = "img/keep/"
DestroyedKeep.icon = "cat1_neutral.png";

--local rnd = math.random;
local round = math.ceil;
local regenSymbolsCount = 5;
local regenSymbolsSize = 8;
local regenSymbolsYoffset = 25+0.5*regenSymbolsSize;

function DestroyedKeep:new(r,u,map, mainEnemyKeep)
    local dKeepConst = require("game.gameConst").DestroyedKeep;
    
    local toughness = dKeepConst.toughness;
    local newDestroyedKeep = require("game.map.buildings.Building"):new("DestroyedKeep",r, u, map,toughness);
    
    -- set meta tables so lookups will work
    setmetatable(newDestroyedKeep, self);
    self.__index = self
    
    
    if(mainEnemyKeep) then
        newDestroyedKeep.mainEnemyKeep = true;
    end
    
    newDestroyedKeep.conversionWorkCost = dKeepConst.conversionWorkCost;
    newDestroyedKeep.regenerationTime = dKeepConst.regenerationTime;
    newDestroyedKeep.regeneration = 0;
    newDestroyedKeep.regStartTime =  -1;
    newDestroyedKeep.regeneration = 0;
    newDestroyedKeep.conversionWorkDone = 0;
    newDestroyedKeep.conversionRequest = nil;
    newDestroyedKeep.conversion = 0;
    newDestroyedKeep.regenSymbols = {};
    newDestroyedKeep.lastAciveRegenSymbol = 0;
    
    
    local clusterNum = map.tiles[r][u].cluster;
    local powerProperties = map.clusters[clusterNum].powerProperties;
    
    newDestroyedKeep.powerCategory = powerProperties.powerCategory;
    
    -- let others know
    newDestroyedKeep:dispatchBuildingCreatedEvent();
    
    return newDestroyedKeep;
end


function DestroyedKeep:initGraphics(x,y,layer, img, mapDebugLayer)    
    self.layer = layer;
    local g = display.newGroup();
    self.g = g;
    self.x = x;
    self.y= y;
    self:insertToCalcIndex(self.layer,g);
    --gx =x
    
    local tileW = 128;
    local imgName;
    
    if(self.mainEnemyKeep) then
        imgName = "home_neutral.png";
    else
        imgName = "cat" .. self.powerCategory .. "_neutral.png";
    end
    self.icon = imgName;
    self.dispObj = img:newTileImg{w=tileW, h=tileW, dir= "keep", name=imgName,cx=x, cy = y, group=g}
    
    
    -- add regeneration symbols
    local rw = tileW*0.5;
    local rdx = regenSymbolsSize+(rw - (regenSymbolsCount*regenSymbolsSize))/(regenSymbolsCount-1);
    local rx = x-rw*0.5+regenSymbolsSize*0.5;
    local ry = y + regenSymbolsYoffset;
    
    
    for i=1, regenSymbolsCount do
        --local symbol = display.newCircle(g, rx, ry, regenSymbolsSize)
        local symbol = display.newImageRect(g, "img/comm/dis_small.png", regenSymbolsSize, regenSymbolsSize)
        symbol.x, symbol.y = rx, ry;
        symbol:setFillColor(0,0,0);
        symbol.alpha = 0.2;
        self.regenSymbols[i] = symbol;
        rx = rx +rdx;
    end
    
    if(mapDebugLayer) then
        self.label = display.newText("" .. self.fitness, x, y, native.systemFont, 14 )
        mapDebugLayer:insert(self.label);
    end
end

--local ceil = math.ceil;
function DestroyedKeep:updateGraphics()
    if(self.destroyed) then return; end;
    
    local activeSymCount = round(self.regeneration*regenSymbolsCount);
    --print("activeSymCount:" .. activeSymCount)
    
    if(activeSymCount > self.lastAciveRegenSymbol) then
        
        for i=self.lastAciveRegenSymbol+1, activeSymCount do
            --print("activating regen symbol: " .. i)
            if(i ~= 0) then  self.regenSymbols[i].alpha = 1; end
        end
        
        self.lastAciveRegenSymbol = activeSymCount;
    end
    
    
    if(self.label) then
        self.label.text = "f:" .. self.fitness .. ", r:" .. round(self.regeneration * 100) .. "%".. ", c:" .. round(self.conversion * 100) .. "%";
    end
end

function DestroyedKeep:requestConversion()
    
    if(self.conversionRequest) then return; end;
    
    local request = {gr=self.r,gu=self.u,amount=self.conversionWorkCost - self.conversionWorkDone,
    onDelivery = function() self:onConversionWorkUnit() end}
    
    Runtime:dispatchEvent{name="minionActionRequest", action="work", request = request}
    
    self.conversionRequest = request;
end

function DestroyedKeep:cancelConversion()
    if(self.conversionRequest==nil) then return; end;
    
    self.conversionRequest.state = "canceled";
    self.conversionRequest = nil;
end

function DestroyedKeep:onConversionWorkUnit()
    --print("DestroyedKeep:onConversionWorkUnit()")
    if(self.destroyed) then return; end;
    
    self.conversionWorkDone = self.conversionWorkDone+1;
    self.conversion = self.conversionWorkDone/self.conversionWorkCost;
    
    if(self.conversion >= 1) then
    --if(self.conversionWorkDone == self.conversionWorkCost) then
        self:onConversion();
    else
        self:updateGraphics();
        -- play sound
        local contX,contY = self.layer:localToContent(self.x, self.y);
        Runtime:dispatchEvent({name="soundrequest", type="playnammed", soundName="work", x=contX, y=contY});
    end
    
end

function DestroyedKeep:onConversion()
    --print("DestroyedKeep:onConversion()");
    -- remove self from map
    self:destroy();
    
    Runtime:dispatchEvent{name =  "keepConverted", keep = self}
end

function DestroyedKeep:updateRegenerationState(timeStamp, aIPlayerBehavior)
    --print("DestroyedKeep:updateRegenerationState(timeStamp, aIPlayerBehavior)");
    
    if(self.regStartTime <= 0) then
        self.regStartTime = timeStamp;
    end
    
    
    local timeSpend =  timeStamp - self.regStartTime;
    
    self.regeneration = timeSpend / self.regenerationTime;
    
    if(self.regeneration >=1) then
        self.regeneration = 1;
        self:onRegenerated(timeStamp, aIPlayerBehavior);
    else
        self:updateGraphics();
    end;
    
end


function DestroyedKeep:onRegenerated(timeStamp, aIPlayerBehavior)
    
    -- remove self from map
    self:destroy();
    
    Runtime:dispatchEvent{name =  "keepRegenerated", keep = self}
    
end

function DestroyedKeep:destroy()
    if(self.destroyed) then return; end;    
    self.destroyed = true;
    
    self:cancelConversion();
    self.map:removeItem(self);
    self.g:removeSelf();
    self.g = nil;
    if(self.label) then
        self.label:removeSelf();
        self.label = nil;
    end
    
end

return DestroyedKeep;

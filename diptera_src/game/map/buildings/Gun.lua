
-- building used to attack enemy teritories
local Gun = {};

setmetatable(Gun, require("game.map.buildings.Building"))
Gun.__index = Gun

Gun.iconDir = "img/gun/"
Gun.icon ="gun_0.25.png";
Gun.progressProperty = {name="charge", max=1, formating="%"} -- property to show in infopanels progress bar

local ceil = math.ceil;
local fireDelay = 400; -- in ms

function Gun:new(r,u,map)
    local gameConst = require("game.gameConst");
    local gunConst = gameConst.Gun;
    
    local newGun = require("game.map.buildings.Building"):new("Gun",r, u, map, gunConst.toughness);
    
    -- set meta tables so lookups will work
    setmetatable(newGun, self)
    self.__index = self
    
    
    newGun.deconstructonReturnsMaterial = true;
    
    newGun.target = nil;
    newGun.charge = 0; -- indicates how much is gun charget, full charge = 1
    --newGun.chargingPeriod = gunConst.firePeriod;
    newGun.chargingWorkCost = gunConst.chargingWorkCost;
    newGun.workSpend = 0;
    newGun.misilesDamage =  gunConst.misilesDamage;
    newGun.chargeWorkRequest = nil;
    
    newGun.chargeStartTime = -1;
    newGun.onTargetHit = nil;
    newGun.pathToTarget = nil;
    newGun.lastImage = nil;
    newGun.loaded = false;
    newGun.bulletTransportRequest = nil;
    newGun.fireDelayTimer = nil;
    
    newGun.targetMarkersGroup = nil;
    newGun.selected = false;
    
    -- let others know
    newGun:dispatchBuildingCreatedEvent()
    
    
    return newGun;
end


function Gun:initGraphics(x,y,layer, aboweMapLayer, img, mapDebugLayer)
    self.layer = layer;
    self.aboweMapLayer = aboweMapLayer;
    self.img = img;
    self.x = x;
    self.y = y;
    --self.dispObj = img:newTileImg{w=128, h=128, dir= "mockup", name="gun.png", cx=x, cy = y} --, group=layer}
    self:updateGraphics();
    --self.layer:insert(self:calcIndex(self.layer),self.dispObj );
    if(mapDebugLayer) then
        self.label = display.newText("", x, y, native.systemFont, 14 )
        mapDebugLayer:insert(self.label);
    end
    
end


function Gun:updateGraphics()
    if(self.destroyed) then return; end;
    
    if(self.label)then
        self.label.text = "f:" .. self.fitness .. ", " .. ceil(self.charge * 100) .. "%";
    end
    
    self:updateImage();
end


function Gun:updateImage()
    --local lastImg = self.lastImage;
    
    -- selecet image name based on charge
    local charge = self.charge;
    local imgName = nil;
    --print("gun-image state: charge: " .. tostring(charge) .. ", loaded: " .. tostring(self.loaded));
    
    if(charge <= 0.25)then
        imgName = "gun_0.png";
    elseif(charge < 0.5)then
        imgName = "gun_0.25.png";
    elseif(charge < 0.75)then
        imgName = "gun_0.5.png";
    elseif(charge <= 1 and self.loaded == false)then
        imgName = "gun_1.png";
    elseif(charge == 1 and self.loaded)then
        imgName = "gun_1_loaded.png";
    else
        print("Warning unknown gun-image state: charge: " .. tostring(charge) .. ", loaded: " .. tostring(self.loaded));
    end
    
    if(imgName ~= self.lastImage) then
        -- update image
        if(self.dispObj) then self.dispObj:removeSelf(); end;
        
        self.dispObj = self.img:newTileImg{w=128, h=128, dir= "gun", name=imgName, cx=self.x, cy = self.y}--, group=self.layer}
        self:insertToCalcIndex(self.layer,self.dispObj);
        --self.layer:insert(self:calcIndex(self.layer),self.dispObj );
        self.lastImage = imgName;
    end
    
end


function Gun:destroy()
    
    if(self.destroyed) then return; end;
    self.destroyed = true;
    
    self.map:removeItem(self);
    --self:removeTargetMarkers();
    self.dispObj:removeSelf();
    self.dispObj = nil;
    if(self.label) then self.label:removeSelf(); self.label = nil; end
    if(self.fireDelayTimer) then timer.cancel(self.fireDelayTimer); self.fireDelayTimer= nil; end;
    
    if(self.bulletTransportRequest) then
        self.bulletTransportRequest.state = "canceled"
        self.bulletTransportRequest = nil;
    end;
    
    if(self.chargeWorkRequest) then
        self.chargeWorkRequest.state = "canceled"; 
        self.chargeWorkRequest = nil;
    end;
end

function Gun:onWorkUnitDone()
    
    -- already charged, can happen when more then one minion is working on charging
    if(self.charge >= 1 or self.bulletTransportRequest) then return; end;
   
    if(self.charge < 1) then
        self.workSpend = self.workSpend +1;
        self.charge =  self.workSpend /self.chargingWorkCost;
    end
    
    if(self.charge >= 1) then
        self.charge = 1;
        self.chargeWorkRequest = nil;
        self:sendBulletTransportRequest();
        --self:fire();
    end
    
    
    self:updateGraphics();
    
    -- play sound
    local x,y = self.layer:localToContent(self.x, self.y);
    Runtime:dispatchEvent({name="soundrequest", type="playnammed", soundName="gun_work", x=x, y=y});

end


function Gun:sendChargingWorkRequest()
    
    if(self.target and self.chargeWorkRequest == nil) then
        local workNeeded = self.chargingWorkCost-self.workSpend;
        
        if(workNeeded > 0) then
            self.chargeWorkRequest = {gr=self.r,gu=self.u,amount=workNeeded,
            onDelivery = function() self:onWorkUnitDone(); end}
        
            Runtime:dispatchEvent{name="minionActionRequest", action="work", request = self.chargeWorkRequest}
        else
            self:sendBulletTransportRequest();
        end
    end
end


function Gun:sendBulletTransportRequest()
    
    -- not loaded
    if(self.target and self.loaded==false and self.bulletTransportRequest == nil )then
        local request = {gr=self.r,gu=self.u,amount=1,itemType="Bullet",
        onDelivery = function() self:onBulletDelivery() end}
        
        Runtime:dispatchEvent{name="minionActionRequest", action="transport", request = request}
        
        self.bulletTransportRequest = request;
        
        -- loaded -> ready to fire
    elseif(self.target and self.loaded and self.bulletTransportRequest == nil) then
        self:onBulletDelivery();
    end
    
end


function Gun:onBulletDelivery()
    if(self.destroyed) then return; end;
    
    self.loaded = true;
    self:updateGraphics();
    
    
    self.fireDelayTimer = timer.performWithDelay(fireDelay, 
    function()
        self:fire();
        self.fireDelayTimer = nil;
    end);
    
    
end


function Gun:fire()
    if(self.destroyed) then return; end;
    if(self.target==nil) then return;  end
    
    
    if(self.target.destroyed) then
        self:stopFiring();
        return;
    end
    
    
    self.bulletTransportRequest = nil;
    
    --local isoGrid =  self.map.isoGrid;
    -- send missile
    local  missile =  require("game.unit.Missile"):new(self.r,self.u,self.gr, self.gu,
    self.map.isoGrid, self.misilesDamage, self.onTargetHit);
    
    missile:move();
    
    self.loaded = false;
    self.charge = 0;
    self.workSpend = 0;
    self:sendChargingWorkRequest();
    self:updateGraphics();
end

function Gun:setTarget(mapItem)
    if(self.destroyed) then return; end;
    
    self:stopFiring();
    
    self.target = mapItem;
    self.onTargetHit = function()
        if(self.target) then -- target can be destroyed after this missile wa launched
            mapItem:hit(self.misilesDamage, "Missile");
            if(self.target.destroyed) then
                self:stopFiring();     
            end
        end
    end
    
    --[[
    self.pathToTarget = {
        {self.r,self.u},
        {mapItem.r, mapItem.u}
    };]]
    self.gr = mapItem.r;
    self.gu = mapItem.u;
    
    self:sendChargingWorkRequest();
        
    Runtime:dispatchEvent{name = "infoevent", info= "gunTargeted"}
    
    -- play sound
    local x,y = self.layer:localToContent(self.x, self.y);
    Runtime:dispatchEvent({name="soundrequest", type="playnammed", soundName="targeted", x=x, y=y});
    
end

function Gun:stopFiring()
    --print("Gun:stopFiring()")
    if(self.chargeWorkRequest) then
        self.chargeWorkRequest.state="canceled";
        self.chargeWorkRequest = nil;
    end
    
    if(self.bulletTransportRequest) then
        self.bulletTransportRequest.state="canceled";
        self.bulletTransportRequest = nil;
    end
    
    
    self.target = nil;
    self.onTargetHit = nil;
    self.pathToTarget = nil;
    
    if(self.selected) then
        self:showTargets();
    end
end

function Gun:onSelection() -- when building is selected, not target
    --print("Warning default: MapItem:onSelection() - does nothing");
    self:showSelection();
    self:showTargets();
    self.selected = true;
    
    --[[
    if(self.target) then
        local isoGrid = self.map.isoGrid;
        local x1,y1 = isoGrid:isoToCart(self.r, self.u);
        local x2,y2 = isoGrid:isoToCart(self.target.r, self.target.u);
        local line = display.newLine(self.layer, x1, y1, x2, y2);
        line:setStrokeColor( 1, 0, 0, 0.5 )
        line.strokeWidth = 3
        
        transition.to(line, {alpha = 0, time = 650, 
            onComplete = function() line:removeSelf(); end
        });
    end
    ]]
end

function Gun:onDeselection()
    
    if(self.targetMarkersGroup) then
        self.targetMarkersGroup:removeSelf();
        self.targetMarkersGroup = nil;
    end
    
    self.selected = false;
end

function Gun:addTargetMarks(group, x, y, color)
    local g = display.newGroup();
    group:insert(g);
    
    local dist = 25;
    local r = 3;
    
    
    local c = display.newCircle(g, -dist, 0, r)
    c:setFillColor(unpack(color));
    c.blendMode="add";
    
    c = display.newCircle(g, dist, 0, r)
    c:setFillColor(unpack(color));
    c.blendMode="add";
    
    c = display.newCircle(g, 0, -dist, r)
    c:setFillColor(unpack(color));
    c.blendMode="add";
    
    c = display.newCircle(g, 0, dist, r)
    c:setFillColor(unpack(color));
    c.blendMode="add";
    
    g.x = x;
    g.y = y;
    g.xScale = 4;
    g.yScale = 4;
    
    self.targetMarkersTransition = transition.to(g, {rotation = 360, xScale =1, yScale=1, time = 850, transition = easing.inOutQuad});
end

function Gun:removeTargetMarkers()
    if(self.targetMarkersGroup) then
        self.targetMarkersGroup:removeSelf();
        self.targetMarkersGroup = nil;
        
        if(self.targetMarkersTransition) then
           transition.cancel(self.targetMarkersTransition);
           self.targetMarkersTransition=nil;
        end
        
    end
end

-- shows all potential targets
function Gun:showTargets()
    
    self:removeTargetMarkers()
    
    
    -- get all adjecent clusters
    local map = self.map;
    local clusNum = map.tiles[self.r][self.u].cluster;
    local neighbors = map.clusters[clusNum].neighbors;
    
    local potTargets = {}; -- list of possible tagets
    
    for neigNum, v in pairs(neighbors) do
        local neighMean = map.clusters[neigNum].meanTile;
        -- get item on mean tile, it can be an enemy keep
        local item = map:getItem( map.tiles[neighMean[1]][neighMean[2]].item);
        
        if(item.typeName == "EnemyKeep") then -- possible target found
            potTargets[#potTargets+1] = item;
        end
    end
    
    
    if(#potTargets <= 0) then return end;
    --print("Found: " .. #potTargets .. " targets");
    
    local g = display.newGroup();
    if(self.aboweMapLayer == nil) then print("WARNING: Gun:showTargets() before graphics init??"); return; end;
    self.aboweMapLayer:insert(g);
    local isoGrid = self.map.isoGrid;
    local x1,y1 = isoGrid:isoToCart(self.r, self.u);
    
    
    
    for i,enemyKeep in ipairs(potTargets) do
                        
        local x2,y2 = isoGrid:isoToCart(enemyKeep.r, enemyKeep.u);
        local line = display.newLine(g, x1, y1, x2, y2);
        
        if(self.target and self.target == enemyKeep) then
            --print("adding target line")
            local tColor = {1, 0.2, 0.2, 0.9};
            line.stroke = {type="image", filename= "img/comm/fuzy_stroke.png"};
            line.strokeWidth = 8;
            line:setStrokeColor( unpack(tColor));
            line.blendMode="add";
            self:addTargetMarks(g, x2, y2, tColor);
            --self.targetMarkersTransition = transition.from(line, {x2=x1+1, y2=y1});
            --line.x2 = line.x2+50;
        else
            
            line.stroke = {type="image", filename= "img/comm/fuzy_stroke.png"};
            line:setStrokeColor( 0.7, 0.4, 0.4, 0.9 )
            --line.stroke  = {type = "gradient", color1 = {0.7,0.5,0.2,alpha }, color2 = { 0.7,0.2,0.2,alpha}, direction = "up"}
            line.strokeWidth = 4;
        end
    end
    
    self.targetMarkersGroup = g;
    
end


function Gun:cancelAllRequests()
    self:cancelRepair();
    if(self.chargeWorkRequest) then
        self.chargeWorkRequest.state="canceled";
        self.chargeWorkRequest = nil;
    end
    
    if(self.bulletTransportRequest) then
        self.bulletTransportRequest.state="canceled";
        self.bulletTransportRequest = nil;
    end
    
end

return Gun;






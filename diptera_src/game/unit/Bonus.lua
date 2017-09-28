


-- unit used to represent some in-game bonuses
local Bonus = {};

setmetatable(Bonus, require("game.unit.Unit"));
Bonus.__index = Bonus;

Bonus.icon= "keep";

function Bonus:new(r,u,map, treasure, context)
    
    local newBonus =require("game.unit.Unit"):new("Bonus");
    
    -- set meta tables so lookups will work
    setmetatable(newBonus, self)
    self.__index = self
    
    newBonus.treasure = treasure;
    newBonus.context = context;
    newBonus.symbolSize = 100;
    newBonus.uiUtils = require("ui.uiUtils");
    newBonus.tapped = false;
    newBonus.destroyed = false;
    
    
    -- let others know
    newBonus:dispatchUnitCreatedEvent(r,u);
    return newBonus;
end


function Bonus:initGraphics(x,y,layer, img, unitDebugLayer)
    
    self.layer = layer;
    local g= display.newGroup();
    self.g = g;
    layer:insert(g);
    self.x = x;
    self.y =y;
    
    local isEmpty = (self.treasure.treasureName == "empty");
    
    if(isEmpty) then
        self:showDesctiption();
        self:animateTap();
    else
        local size = self.symbolSize;    
        
        local image = img:newTileImg{w=size, h=size, dir= "bonus", name="bonus.png", group=g, cx=x, cy = y}
        self.dispObj = image;
        image:addEventListener("tap", function() return self:onTap(); end)
        --print("bonus: x,y:" ..x .. ", " .. y);
        
        -- show some effect to lure player to touch it
        local smallSize = size*0.6;
        local time = 350;
        local sizeTweenList = {
            {width=smallSize, height=smallSize, time=time},
            {width=size, height=size, time = time},
        }
        
        local f = image.fill;
        --f.effect = "filter.brightness";
        f.effect ="filter.desaturate";
        f.effect.intensity = 0.0;
        
        local intensityTweenList = {
            {intensity=0.5, time=time},
            {intensity=0.0, time=time},
        }
        
        self.sizeTween =  self.uiUtils.startTransitionList(image, sizeTweenList, -1);
        self.brightnessTween =  self.uiUtils.startTransitionList(f.effect, intensityTweenList, -1);
        --print("self.sizeTween: " .. self.sizeTween .. ", self.brightnessTween:" .. self.brightnessTween);
    end
    
end


function Bonus:updateGraphics()
    --[[
    if(self.label) then
        self.label.text = tostring(self.fitness);    
    end
    ]]
end

function Bonus:onTap()
    if(self.tapped) then return true; end;
    self.tapped = true;
    
    --print("Bonus:onTap()")
    
    
    -- cancel all transitions
    if(self.sizeTween) then
        self.uiUtils.cancelTransitionList(self.sizeTween);
        self.sizeTween = nil;
    end
    
    if(self.brightnessTween) then
        self.uiUtils.cancelTransitionList(self.brightnessTween);
        self.brightnessTween = nil;
        self.dispObj.fill.effect = nil;
    end
    
    self:showDesctiption();
    self:animateTap();
    
    Runtime:dispatchEvent({name="soundrequest", type="button"}); -- play button sound
    return true;
end

function Bonus:showDesctiption()
    
    
    local x,y = self.x,self.y--+0.5*size+0.5*backH;
    self.inGamePanel =  require("ui.info.InGameInfoPanel"):new(x,y,self.layer,self.context, nil, nil, self:getBonusText())
    
    --[[
    local size = self.symbolSize;
    local uiConst = self.context.uiConst;
    local fontSize =  uiConst.bigFontSize;
    local margin = uiConst.defaultMargin;
    local backH = fontSize+2*margin; --1.3*fontSize;
    --local w = 300;
    
    local x,y = self.x,self.y+0.5*size+0.5*backH;
    
    local descG = display.newGroup();
    self.g:insert(descG);
    self.descG = descG;
    
    -- add backround
    local back = display.newRoundedRect(descG, x, y, 100, backH, 5)
    back:setFillColor(0.3,0.3,0.3,0.85);
    
    -- add label
    self.label  = display.newText{ -- contracted or tips label
        text= self:getBonusText(),
        parent = self.layer,
        x = x,
        y = y,
        --width = w,
        height = 0,
        font= uiConst.fontName,
        fontSize = fontSize,
        align = "center"
    }
    self.label.blendMode = "add";
    descG:insert(self.label);
    
    back.width = self.label.width + 2*margin;
    --self.label:setFillColor(unpack(uiConst.defaultFontColor));
    self.label:setFillColor(unpack(uiConst.highlightedFontColor));
    ]]
end


function Bonus:getBonusText()
    local treasureName = self.treasure.treasureName;
    local multiplier = self.treasure.treasureParams.multiplier;
    if(multiplier and multiplier>1) then
        multiplier = multiplier -1;
    end
    
    local textSource = self.context.textSource;
    
    if(treasureName == "empty") then
        return textSource:getText("treasure.empty");
    elseif(treasureName == "movementBoost") then
        return textSource:getText("treasure.mov") .. "+" .. (multiplier*100) .. "%"
    elseif(treasureName == "wallBoost") then
        return textSource:getText("treasure.wall") .. "+" .. (multiplier*100) .. "%"
    elseif(treasureName == "workBoost") then
        return textSource:getText("treasure.work") .. "+" .. (multiplier*100) .. "%"
    elseif(treasureName == "gunBoost") then
        return textSource:getText("treasure.gun") .. "+" .. (multiplier*100) .. "%"
    else
        print("Warning: unknown trasure name :" .. tostring(treasureName));
        return "";
    end
    
end

function Bonus:animateTap()
    --self.dispObj:removeSelf()
    local time = 850;
    local image = self.dispObj;
    
    if(image) then
        transition.cancel(image)
        --local transList = {}
        transition.to(image, {y=image.y-1500, rotation = 1080,  time = time, transition = easing.inCubic,
        onComplete = 
            function()
                self:destroy();
            end
        } )
    end
    
    
    self.inGamePanel:fadeOut();
    
end


function Bonus:destroy()
    if(self.destroyed) then return end;
    self.destroyed = true;
    
    
    if(self.dispObj) then
        transition.cancel(self.dispObj);
    end
    
    if(self.g) then
        transition.cancel(self.g);
        self.g:removeSelf();
        self.g = nil;
    end
    
end

return Bonus;








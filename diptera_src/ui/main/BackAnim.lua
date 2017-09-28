

local BackAnim = {}

local rnd = math.random;

function BackAnim:new(layer, context)
    
    
    local newBackAnim= {};
    
    setmetatable(newBackAnim, self);
    self.__index = self; 
    
    newBackAnim.layer =layer;
    newBackAnim.context = context;
    
    newBackAnim:init(layer, context);
        
    
    return newBackAnim;
end

function BackAnim:init(layer, context)
    
    local g = display.newGroup();
    self.g = g;
    layer:insert(g);
    
    local bounds = context.displayBounds;
    local uiConst = context.uiConst;
    
    
    -- add stars
    self.stars =  require("ui.main.Stars"):new(layer, bounds.minX, bounds.minY, bounds.maxX, bounds.minY+ 0.2*bounds.height, rnd(10,20));
    
    self:addLogo(g, context);
    self:addBackscape(layer, context)
    
    --local startColor = {0.54,0.53,84};--{92,68,44}--{0.54,0.53,84};
    local margin = 0--uiConst.defaultMargin;
    
    local tileH = 35;
    local thickness = tileH-margin;
    local startY = bounds.minY+bounds.height*0.4;
    local stripeW = bounds.width+0.5*thickness;
    local stripeH = 0.25*stripeW;--0.25*bounds.height;
    local stripeX = bounds.centerX;
    local stripeY = startY;
    local mask = graphics.newMask("img/comm/mm_stripes_mask.png")
    local maskSize = 64;
    local numOfStripes = math.floor( (bounds.height-startY)/(thickness+margin))+1;
    --print("numOfStripes :" .. numOfStripes)
    local startAlpha = 0.05;
    local endAlpha = 0.2;
    local alpha = startAlpha;
    local da = (startAlpha-endAlpha)/(numOfStripes-1);
    self.selectedAlpha = 1.5*startAlpha;
    
    local stripes = {};
    local alphas = {};
    
    
    for i=1, numOfStripes do
        
        local stripe = self:createBackStripe(g,stripeX,stripeY,stripeW,stripeH,thickness, mask, maskSize);
        --stripe:setFillColor(unpack(startColor));
        
        local gradient = {
            type = "gradient",
            color1 = uiConst.backgroundBottomColor,
            color2 = uiConst.backgroundTopColor,
            direction = "up"
        }
        
        stripe.fill =  gradient;
        stripe.alpha = alpha;
        stripe.strokeWidth = 2;
        stripe:setStrokeColor(unpack(uiConst.backgroundTopColor))
        --stripe:setStrokeColor(0.5)
        stripe.blendMode = "add";
        --stripe.blendMode = "screen";
        
        --local cic = display.newCircle(g, stripeX, stripeY, 5)
        --cic:setFillColor(0.9,0.1,0.1);
        --cic.alpha = 0.5;
        alphas[#alphas+1] = alpha;
        alpha = alpha - da;
        stripes[#stripes+1] = stripe;
        stripeY = stripeY + thickness + margin;
    end
    
    self.stripes = stripes;
    self.alphas = alphas;
    
    
    
    self:addBludicky(g, context);
    self:addSunCrystal(g, context);
    --self:addLogo(g, context);
    
    self:stripesAnim(#self.stripes);
    return self;
end
local stripeInTime = 1250;
function BackAnim:stripesAnim(index, delay)
    
    transition.to(self.stripes[index], {alpha=0.2, time=stripeInTime, delay=delay, transition=  easing.inOutCubic, onComplete = 
        function()
            transition.to(self.stripes[index], {alpha=self.alphas[index],transition= easing.inCubic , time = 3.5*stripeInTime});
            if(index>1) then
                self:stripesAnim(index-1);
            elseif(index == 1) then
                self:stripesAnim(#self.stripes, rnd(500,5000));
            end
        end, 
    });
    
end

local function addMountain(layer,x,y,w,h,c1,c2,strokeColor, mask, maskSize)
    
    local m = display.newPolygon(layer, x,y+0.5*h, {0,0,w*0.5,h,-0.5*w,h});
    m.fill = {
        type = "gradient",
        color1 = c1,
        color2 = c2,
        --color2 = uiConst.backgroundTopColor,
        direction = "up";
    }
    
    m:setMask(mask);
    m.maskScaleX = w/maskSize;
    m.maskScaleY = h/maskSize;
    
    m.stroke = {type="image", filename="img/comm/mm_stripe_stroke.png"};
    m:setStrokeColor(unpack(strokeColor))
    m.strokeWidth = 4;
    
    --m.alpha = 0.6;
    
    return m;
end

function BackAnim:addBackscape(layer, context)
    
    local bounds = context.displayBounds;
    local uiConst = context.uiConst;
    local mask = graphics.newMask("img/comm/mm_stripes_mask.png")
    local maskSize = 64;
    
    --local c = uiConst.backgroundTopColor;
    --local o = 0.9;
    --local c2 = {c[1]*o, c[2]*o,c[3]*o};
    local c1 = uiConst.backgroundBottomColor;
    local c2 = {0.77,0.46,0.17};
    local strokeColor = uiConst.backgroundTopColor;
    
    --[[
    local gradient= {
        type = "gradient",
        color1 = uiConst.backgroundBottomColor,
        color2 = c2,
        --color2 = uiConst.backgroundTopColor,
        direction = "up"
    }
    ]]
    
    local minY = bounds.minY+bounds.height*0.60; 
    --display.newLine(layer, bounds.minX, minY, bounds.maxX, minY);
    
    local x= bounds.minX+bounds.width*0.35;
    local h,w  = bounds.height*0.25, bounds.width*0.25;
    local y = minY - 1.6*h;
    local m;
    m = addMountain(layer,x,y,w,h,c1,c2,strokeColor, mask, maskSize)
    m.alpha = 0.4;
    
    x= bounds.minX+bounds.width*(1-0.35);
    m = addMountain(layer,x,y,w,h,c1,c2,strokeColor, mask, maskSize);
    m.alpha = 0.4;
    
    x,y = bounds.minX+bounds.width*0.05, bounds.minY+bounds.height*0.05;
    h,w  = bounds.height*0.55, bounds.width*0.55;
    
    addMountain(layer,x,y,w,h,c1,c2,strokeColor, mask, maskSize)
    
    x= bounds.minX+bounds.width*0.95;
    addMountain(layer,x,y,w,h,c1,c2,strokeColor, mask, maskSize)
    
    
    
    --[[
    local m1 = display.newPolygon(layer, x,y+0.5*h, {0,0,w*0.5,h,-0.5*w,h});
    m1.fill = gradient;
    m1:setMask(mask);
    m1.maskScaleX = w/maskSize;
    m1.maskScaleY = (h)/maskSize;
    
    m1.stroke = {type="image", filename="img/comm/mm_stripe_stroke.png"};
    m1:setStrokeColor(unpack(uiConst.backgroundTopColor))
    m1.strokeWidth = 4;
    
    m1.alpha = 0.6;
    
    
    x= bounds.minX+bounds.width*0.95
    --h,w  = bounds.height*0.55, bounds.width*0.55;
    
    local m2 = display.newPolygon(layer, x,y+0.5*h, {0,0,w*0.5,h,-0.5*w,h});
    m2.fill = gradient;
    m2:setMask(mask);
    m2.maskScaleX = w/maskSize;
    m2.maskScaleY = (h)/maskSize;
    
    m2.stroke = {type="image", filename="img/comm/mm_stripe_stroke.png"};
    m2:setStrokeColor(unpack(uiConst.backgroundTopColor))
    m2.strokeWidth = 4;
    ]]
    --m2.alpha = 0.6;
    
    --m1.blendMode = "multiply"
    --m1.blendMode  = "add";
    
    --local cic = display.newCircle(layer, x, y, 5)
    --cic:setFillColor(0.9,0.1,0.1);
    --cic.alpha = 0.5;
    
    
end


function BackAnim:addBludicky(g, context)
    
    local bludicky = {};
    local bounds = context.displayBounds;
    
    for i =1, 10 do
        local bludicka = require("ui.main.Bludicka"):new(g,context,bounds.minX,bounds.minY, bounds.maxX, bounds.minY + bounds.height*0.45, true );
        bludicky[#bludicky+1] = bludicka;
    end
    
    for i =1, 10 do
        local bludicka = require("ui.main.Bludicka"):new(g,context,bounds.minX,bounds.centerY, bounds.maxX, bounds.maxY, false );
        bludicky[#bludicky+1] = bludicka;
    end
    
    self.bludicky = bludicky;
end

function BackAnim:addLogo(group, context)
    local bounds = context.displayBounds;
    local uiConst = context.uiConst;
    local margin = uiConst.defaultMargin;
    local h = 140;
    local name = context.textSource:getText("mm.gameName");
    local w = 0;
    --local dx = w / #name;
    
    local g = display.newGroup();
    self.logoGroup = g;
    group:insert(g);
    
    local x = bounds.centerX-50;
    --local x = bounds.minX;
    local y  = bounds.minY + 0.5*h + margin;
    local alpha = 1.0;
    local color = {1,0.7,0.7}--{0.5,0.5,0.75} --uiConst.highlightedFontColor
    
    
    local label  = display.newText{ -- game name
        text= name;--tostring(name:sub(i,i)),
        parent = g,
        x = x,--left+margin,--cx,
        y = y,
        --width = labelW,
        height = 0,
        font= uiConst.fontName,
        fontSize = h,
        align = "center",
    }
    label.alpha = alpha;
    
    label.fill = {
        type = "image",
        filename = "img/back.png"
    }
    local fillScale = label.width/512;
    label.fill.scaleX = fillScale;
    label.fill.scaleY = fillScale;
    label.blendMode = "add";
    label:setFillColor(unpack(color));
    
    w = w+label.width;
    
    
    --add line
    local line = display.newLine(g, x-0.5*w-margin, y+0.4*h, x+0.5*w+margin, y+0.4*h);
    line.alpha = 0.5
    line:setStrokeColor(unpack(color));
    line.strokeWidth = 2;
    line.blendMode = "add";
    
    
    -- add mask to whole group
    local logoMask = graphics.newMask("img/comm/logo_mask.png");
    local maskSize = 64;
    g:setMask(logoMask);
    
    local maskingSpace = 2*w;
    local maskScale = maskingSpace/maskSize;
    
    g.maskScaleX = maskScale;
    g.maskScaleY = maskScale;
    g.maskX = x;
    g.maskY = y;
    
    local maxDevX = 0.25*maskingSpace;
    local maxDevY = 0.5*(maskingSpace-h*1.3);
    
    local abs = math.abs;
    local max = math.max;
    
    local function traslateMask()
        local gx = x + rnd(-1,1)*maxDevX;
        local gy = y + rnd(-1,1)*maxDevY;
        local dist = max(abs(g.maskX-gx), abs(g.maskY-gy));
        local time = dist*1000/20;
        transition.to(g, { maskX = gx, maskY = gy, time = time, transition = easing.inOutQuad,
            onComplete = 
            function()
                traslateMask();
            end
        });
    end
    
    traslateMask();
    
    
    --[[ --show mask position and boundary
    display.newRect(g, x, y, maskingSpace, maskingSpace);
    local r = display.newRect(group, x, y, maskingSpace, maskingSpace);
    r:setFillColor(0,0); r.strokeWidth = 3; r:setStrokeColor(1,0,0,1);
    ]]
    
    
    
    --[[
    o.fill.effect = "filter.blurGaussian"
    local blurSize = 50;
    local sigma = 140;
    o.fill.effect.horizontal.blurSize = blurSize
    o.fill.effect.horizontal.sigma = sigma
    o.fill.effect.vertical.blurSize = blurSize
    o.fill.effect.vertical.sigma = sigma
    ]]
end

function BackAnim:addSunCrystal(g, context)
    
    local bounds = context.displayBounds;
    local uiConst = context.uiConst;
    local margin = uiConst.defaultMargin;
    
    local size = 80--;bounds.height*0.3;
    --local sh = 0.5*size;
    local x,y = bounds.maxX - bounds.width*0.2-0.5*size, bounds.minY + bounds.height*0.3 - 0.5*size;
    
    -- add sun crystal image
    local icon  =  display.newImageRect(g, "img/bonus/bonus.png", size, size);
    self.sunIcon = icon;
    icon.alpha = 0.65;
    local uiUtils = require("ui.uiUtils");
    self.uiUtils = uiUtils;
    
    icon.x = x;
    icon.y = y;
    
    -- animate logo
    -- show some effect to lure player to touch it
    local smallSize = size*0.85;
    local time = 2300;
    local sizeTweenList = {
        {width=smallSize, height=smallSize, alpha=0.65, time=time},
        {width=size, height=size, alpha=1, time = time},
    }
    
    local f = icon.fill;
    --f.effect = "filter.brightness";
    --f.effect ="filter.desaturate";
    --f.effect.intensity = 0.0;
    
    f.effect = "filter.contrast";
    f.effect.contrast = 1;
    
    local intensityTweenList = {
        {contrast=1.0, time=time, transition = easing.inOutCubic},
        {contrast=1.5, time=time,  transition=easing.inCubic},
    }
    
    --[[
    local intensityTweenList = {
        {intensity=0.0, time=time},
        {intensity=0.2, time=time},
    }
    ]]
    
    self.sizeTween =  uiUtils.startTransitionList(icon, sizeTweenList, -1);
    self.brightnessTween = uiUtils.startTransitionList(f.effect, intensityTweenList, -1);
    --print("self.sizeTween: " .. self.sizeTween .. ", self.brightnessTween:" .. self.brightnessTween);
    
    local emmitter = require("ui.particles").newEmitter("icon_par");
    self.emmitter = emmitter;
    g:insert(emmitter);
    emmitter.x = icon.x;
    emmitter.y = icon.y;
    
    
    -- ocassional icon rotation
    local function rotIcon(now)
        
        local delay;
        
        if(now) then
            delay = 850;
        else
            delay = 6500+rnd()*8500;
        end
        
        transition.to(icon, {rotation=360, time = 650, delay= delay,
            transition =   easing.inOutQuint ,
            onComplete= 
            function()
                icon.rotation = 0;
                rotIcon();
            end
            , onStart=
            function()
                timer.performWithDelay(150, 
                function()
                    if(self.emmitter) then
                        self.emmitter:start();
                    end
                end
                , 1)
                
            end,
        });
    end
    
    rotIcon(true);
    
end


--[[
function BackAnim:selectStripe(index)
    --print("BackAnim:selectStripe(".. tostring(index) .. ")")
    
    local stripes = self.stripes;
    local alphas = self.alphas;
    local offAlpha = 0.05;
    local transTime = 350;
    
    for i=1,#stripes do
        
        local stripe = stripes[i];
        transition.cancel(stripe);
        
        if(i< index) then -- stripes below the selected one
            if(stripe.alpha~=offAlpha) then
                transition.to(stripe,{alpha=offAlpha, time=transTime});
            end
        elseif(i==index) then -- the selected stripe
            if(stripe.alpha~=self.selectedAlpha) then
                transition.to(stripe,{alpha=self.selectedAlpha, delay=250, time=transTime});
            end
        else -- tripes above 
            if(stripe.alpha~=alphas[i]) then
                transition.to(stripe,{alpha=alphas[i], time=transTime});
            end
        end
    end
    
end
]]

function BackAnim:createBackStripe(g,x,y,w,h,thickness, mask, maskSize)
    
    
    
    --local wh = 0.5*w;
    --local line = display.newLine(g, x-wh, y+h, x, y,x+wh,y+h);
    --stripe.strokeWidth = thickness;
    --stripe.stroke = {type="image", filename="img/comm/mm_stripes.png"}
    
    
    
    local hh = 0.5*h;
    local wh = 0.5*w;
    local cx, cy = x, y + hh+0.5*thickness;
    local stripe = display.newPolygon(g, cx,cy, {x-wh, y+h, x,y,x+wh, y+h, x+wh, y+h+thickness, x, y+thickness,x-wh, y+h+thickness});
    --stripe.strokeWidth = 6;
    stripe.stroke = {type="image", filename="img/comm/mm_stripe_stroke.png"};
    
    --stripe.fill = {type="image", filename="img/comm/mm_stripes.png"};
    --stripe.fill.rotation = 26.565;
    --stripe.fill.rotation = 90
    
    
    stripe:setMask(mask);
    stripe.maskScaleX = thickness/maskSize;
    stripe.maskScaleY = h/maskSize;
    
    
    return stripe;
end


function BackAnim:destroy(layer)
    
    if(self.logoGroup) then
        transition.cancel(self.logoGroup);
        self.logoGroup:removeSelf();
        self.logoGroup = nil;
    end
    
    if(self.sunIcon) then
        transition.cancel(self.sunIcon);
        --self.sunIcon = nil; -- see below
    end
    
    if(self.emmitter) then
        self.emmitter:stop();
        self.emmitter:removeSelf();
        self.emmitter = nil;
    end
    
    if(self.sizeTween) then
        self.uiUtils.cancelTransitionList(self.sizeTween);
        self.sizeTween = nil;
    end
    
    if(self.brightnessTween) then
        self.uiUtils.cancelTransitionList(self.brightnessTween);
        self.brightnessTween = nil;
        self.sunIcon.fill.effect = nil;
        self.sunIcon = nil;
    end
    
    
    if(self.bludicky) then
        for k,bludicka in ipairs(self.bludicky) do
            bludicka:destroy();
        end
    end
    
    
    if(self.stripes) then
        
        for i,stripe in ipairs(self.stripes) do
            transition.cancel(stripe);
        end
        
        self.stripes = nil;
    end
    
    if(self.stars) then
        self.stars:destroy();
        self.stars = nil;
    end
    
    if(self.g) then
        self.g:removeSelf();
        self.g = nil;
        
        self.alphas = nil;
    end
    
end






return BackAnim;

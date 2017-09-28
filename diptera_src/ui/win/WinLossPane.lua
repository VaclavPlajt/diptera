

local WinLossPane = {}

local popTime = 350;
--local leftShift = -150;
local w = 750;
local iconSize = 128;
local rnd = math.random;

function WinLossPane:new(layer,onRepeat,onOk, win, context)
    local newWL = {}
    
    -- set meta tables so lookups will work
    setmetatable(newWL, self)
    self.__index = self
    
    
    local bounds =  context.displayBounds;
    local uiConst = context.uiConst;
    local margin = uiConst.defaultMargin;
    local textSource = context.textSource;
    
    
    local g = display.newGroup();
    layer:insert(g);
    newWL.g = g;
    
    
    
    local cx, cy = bounds.centerX, bounds.centerY;
    newWL.cx =cx; newWL.cy = cy;
    
    local btnH = uiConst.defaultBtnHeight;
    local btnW = 3*btnH;
    local h = iconSize + btnH+3*margin;
    newWL.h = h;
    
    local btnY = cy + 0.5*h - margin - 0.5*btnH;
    
    local uiUtils = require("ui.uiUtils");
    
    -- add event block
    local eventBlocker =  uiUtils.newTouchEventBlocker(g,context);
    newWL.eventBlocker = eventBlocker;
    
    
    -- add background
    local back  = uiUtils.newUiBackRect(g, cx,cy , w, h, context,10, true);
    back.alpha = uiConst.uiPaneAlpha;
    newWL.back = back;
    
    -- add group for background effects
    newWL.bg = display.newGroup();
    g:insert(newWL.bg);
    
    local imgFile;
    local s;
    if(win) then
        s = textSource:getText("looseWin.win");
        imgFile = "img/keep/home.png";
    else
        s = textSource:getText("looseWin.loss");
        imgFile = "img/keep/home_covered.png";
    end
    
    local upperY = cy-btnH*0.5;
    
    -- add icon
    local icon = display.newImageRect(g, imgFile, iconSize, iconSize);
    icon.x = cx - 0.5*w + margin + 0.5*iconSize;
    icon.y = upperY;
    newWL.icon = icon;
    
    -- add text
    newWL.label  = display.newText{ -- label
        text= s,
        parent = g,
        x = cx-margin+0.5*iconSize,
        y = upperY,
        width = w - 2* margin-iconSize,
        height = 0,
        font= uiConst.fontName,
        fontSize = uiConst.hugeFontSize,
        align = "center"
    }
    
    newWL.label:setFillColor(unpack(uiConst.highlightedFontColor));
    newWL.label.blendMode = "add";
    -- add buttons
    -- add repeat button
    
    newWL.onRepeat = onRepeat;
    newWL.repeatBtn = context.img:newBtn{dir="ui/actions", name="default",group = g,
        cx =  cx - 0.5*w + margin + 0.5*btnW, cy = btnY,
        w=btnW, h=btnH, hasOver=true,
        onAction = function(event) newWL:onRepeatBtn() end,
        label = textSource:getText("looseWin.repeatBtn"), labelColor = uiConst.defaultBtnLabelColor, fontSize = uiConst.defaultBtnFontSize 
    };
    
    -- add ok button
    
    newWL.onOk = onOk;
    newWL.yesBtn = context.img:newBtn{dir="ui/actions", name="default",group = g,
        --cx =  cx , cy = btnY,
        cx =  cx + 0.5*w - margin - 0.5*btnW, cy = btnY,
        w=btnW, h=btnH, hasOver=true,
        onAction = function(event) newWL:onOkBtn() end,
        label = textSource:getText("looseWin.okBtn"), labelColor = uiConst.defaultBtnLabelColor, fontSize = uiConst.defaultBtnFontSize 
    }
    
    -- pop-in
    g.alpha = 0;
    transition.to(g, {alpha=1, time = popTime, onComplete = 
        function()
           if(win)  then
               newWL:winAnimation();
           else
               newWL:lossAnimation();
           end
        end
    });
    
end

function WinLossPane:onRepeatBtn()
    
    Runtime:dispatchEvent({name="soundrequest", type="button"}); -- play button sound
    self:removeSelf();
    if(self.onRepeat) then
        self.onRepeat();
    end
end

function WinLossPane:onOkBtn()
    
    Runtime:dispatchEvent({name="soundrequest", type="button"}); -- play button sound
    self:removeSelf();
    if(self.onOk) then
        self.onOk();
    end
end

function WinLossPane:addDisMark()
    
    
    
    local size = self.minSize + (self.maxSize-self.minSize)*rnd();
    
    local img = display.newImageRect(self.bg, "img/comm/dis_1.png",size , size);
    img.x = self.cx + (w+125)*(rnd()-0.5);
    img.y = self.cy + (self.h+125)*(rnd()-0.5);
    
    img.alpha = 0;
    transition.to(img, {alpha=1, time = 150});
    
    self.count = self.count+1;
    
    if(self.count < self.maxCount) then
        local delay = self.minDelay+(self.maxDelay-self.minDelay)*rnd();
        --print("addDisMark(), size: " .. delay);
        self.timer =  timer.performWithDelay(delay,
            function() self:addDisMark() end,
        1);
    end
end

function WinLossPane:lossAnimation()
    --local imgFile = ;
    
    self.maxDelay = 100;
    self.minDelay = 25;
    self.minSize = 16;
    self.maxSize = 64;
    self.maxCount = 50;
    self.count = 0;
    
    self.timer =  timer.performWithDelay(500,
        self:addDisMark()
    , 1)
end


function WinLossPane:shineCycle(delay)
    
    local shine = self.shine;
    shine.rotation = 0;
    local delayy = delay or 1500+rnd()*(3500)
    
    transition.to(shine, {rotation=150, alpha=1, time = 850, delay = delayy, onComplete = 
        function()
            transition.to(shine, {rotation=300, alpha=0, time =500, onComplete = 
            function()
                self:shineCycle();
            end
            });
        end
    });
    
end

function WinLossPane:winAnimation()
    
    local size = 64;
    local icon = self.icon;
    local img = display.newImageRect(self.g, "img/comm/shine.png",size , size);
    img.x = icon.x + 0.5*icon.width*0.1;
    img.y = icon.y - 0.5*icon.height*0.9;
    img.alpha = 0;
    
    self.shine = img;
    
    
    self:shineCycle(250);
    
    --[[
    local rect = display.newRect(self.g, self.cx, self.cy, 150, 150);
    rect.fill.effect = "generator.lenticularHalo";
    local e = rect.fill.effect;
    e.posX = 0.5;
    e.posY = 0.5;
    e.aspectRatio = 1;--( rect.width / rect.height )
    e.seed = system.getTimer();
    ]]
    
    --add background particles
    local emitter = require("ui.particles").newEmitter("win");
    emitter.x = icon.x;
    emitter.y = icon.y;
    self.bg:insert(emitter);
    self.backEmitter = emitter;
end

function WinLossPane:removeSelf()
    
    if(self.g == nil) then return; end;
    
    if(self.timer) then
        timer.cancel(self.timer);
        self.timer = nil;
    end
    
    if(self.shine) then
        transition.cancel(self.shine);
    end
    
    if(self.backEmitter) then
        self.backEmitter:removeSelf();
        self.backEmitter = nil;
    end
    
    transition.cancel(self.g);
    transition.to(self.g, {alpha=0, time = popTime, onComplete = 
        function()
            self.g:removeSelf();
            self.g = nil;
        end
    });
    
end












return WinLossPane;




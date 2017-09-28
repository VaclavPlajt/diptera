

local RateMePane = {}

local popTime = 350;
--local leftShift = -150;

local iOSAppId = "964468248";
local developerEmail = "wercajkapps@gmail.com";

function RateMePane:new(layer, context)
    local newRatePane = {}
    
    -- set meta tables so lookups will work
    setmetatable(newRatePane, self)
    self.__index = self
    
    newRatePane.context = context;
    local bounds =  context.displayBounds;
    local uiConst = context.uiConst;
    local margin = uiConst.defaultMargin;
    local textSource = context.textSource;
    
    local w =  800;
    local h =  250;
    
    --local minionAssignerWidth = 255;
    --local leftShift = -150;
    
    local g = display.newGroup();
    layer:insert(g);
    newRatePane.g = g;
    
    local cx, cy = bounds.centerX --[[-0.5*minionAssignerWidth]], bounds.centerY;
    
    local btnH = uiConst.defaultBtnHeight;
    local btnW = 4.25*btnH;
    local btnY = cy + 0.5*h - margin - 0.5*btnH;
    
    local uiUtils = require("ui.uiUtils");
    
    -- add event block
    local eventBlocker =  uiUtils.newTouchEventBlocker(g,context);
    newRatePane.eventBlocker = eventBlocker;
    
    -- add background
    local back  = uiUtils.newUiBackRect(g, cx,cy , w, h, context,10, true);
    back.alpha = uiConst.uiPaneAlpha;
    newRatePane.back = back;
    
    -- add labet
    self.label  = display.newText{ -- label
        text= textSource:getText("rateme.text"),
        parent = g,
        x = cx,
        y = cy-btnH*0.5,
        width = w - 3* margin,
        height = 0,
        font= uiConst.fontName,
        fontSize = uiConst.normalFontSize,
        align = "center"
    }
    
    self.label:setFillColor(unpack(uiConst.defaultFontColor));
    
    -- add buttons
    
    -- add later button    
    newRatePane.laterBtn = context.img:newBtn{dir="ui/actions", name="default",group = g,
        cx =  cx - 0.5*w + margin + 0.5*btnW, cy = btnY,
        w=btnW, h=btnH, hasOver=true,
        onAction = function(event) newRatePane:onLaterBtn() end,
        label = textSource:getText("rateme.laterBtn"), labelColor = uiConst.defaultBtnLabelColor, fontSize = uiConst.defaultBtnFontSize
    }
        
    
    -- add improve button
    newRatePane.improveBtn = context.img:newBtn{dir="ui/actions", name="default",group = g,
        cx =  cx, cy = btnY,
        w=btnW, h=btnH, hasOver=true,
        onAction = function(event) newRatePane:onImproveBtn() end,
        label = textSource:getText("rateme.improveBtn"), labelColor = uiConst.defaultBtnLabelColor, fontSize = uiConst.defaultBtnFontSize 
    }
    
    
    -- add like button
    newRatePane.likeBtn = context.img:newBtn{dir="ui/actions", name="default",group = g,
        cx =  cx + 0.5*w - margin - 0.5*btnW , cy = btnY,
        w=btnW, h=btnH, hasOver=true,
        onAction = function(event) newRatePane:onLikeBtn() end,
        label = textSource:getText("rateme.likeBtn"), labelColor = uiConst.defaultBtnLabelColor, fontSize = uiConst.defaultBtnFontSize 
    }
    
    -- pop-in
    g.alpha = 0;
    transition.to(g, {alpha=1, time = popTime});
    
    -- log it
    local settings = context.settings;
    if(settings.rateMeWinShownsCount ==nil) then
        settings.rateMeWinShownsCount = 1;
    else
        settings.rateMeWinShownsCount = settings.rateMeWinShownsCount + 1;
    end
    -- save settings to persistent memory
    context.settingsIO:persistSettings();
    
    context:analyticslogEvent("RateMeWin-Shown", {windowShownCOunt = settings.rateMeWinShownsCount})
    
    return newRatePane;
end

function RateMePane:onLaterBtn()
    
    Runtime:dispatchEvent({name="soundrequest", type="button"}); -- play button sound
    self:removeSelf();
    
    self.context:analyticslogEvent("RateMeWin-Later")
    
end

function RateMePane:onImproveBtn()
    
    --Runtime:dispatchEvent({name="soundrequest", type="button"}); -- play button sound
    self:removeSelf();
    local textSource = self.context.textSource;
    
    local options = {
        subject = textSource:getText("rateme.mailSubject"),
        textSource:getText("rateme.mailBody"),
        to=developerEmail
    }
     
    
    native.showPopup( "mail",options);
        
    self.context:analyticslogEvent("RateMeWin-NeedImprovements");
    
    self.context.settings.canShowRateMeWin = false;
    -- save settings to persistent memory
    self.context.settingsIO:persistSettings();
    
    --print("RateMePane:onImproveBtn()");
end

function RateMePane:onLikeBtn()
    
    --Runtime:dispatchEvent({name="soundrequest", type="button"}); -- play button sound
    self:removeSelf();
    --print("RateMePane:onLikeBtn()");
    
    local device = self.context.device;
    
    if(device.isApple) then
        native.showPopup("appStore", {iOSAppId=iOSAppId});
    else
        native.showPopup("appStore");--, {iOSAppId=iOSAppId});
    end
    
    self.context:analyticslogEvent("RateMeWin-ILikeIt")
    
    self.context.settings.canShowRateMeWin = false;
    -- save settings to persistent memory
    self.context.settingsIO:persistSettings();
    
end

function RateMePane:removeSelf()
    
    if(self.g == nil) then return; end;
    
    transition.cancel(self.g);
    transition.to(self.g, {alpha=0, time = popTime, onComplete = 
        function()
            self.g:removeSelf();
            self.g = nil;
        end
    });
    
    
end




return RateMePane;




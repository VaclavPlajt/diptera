

local OptionPane = {}

local popTime = 350;
--local leftShift = -150;

function OptionPane:new(layer, width,height,textKey,onYes,onNo,onOk, context)
    local newOP = {}
    
    -- set meta tables so lookups will work
    setmetatable(newOP, self)
    self.__index = self
    
       
    local bounds =  context.displayBounds;
    local uiConst = context.uiConst;
    local margin = uiConst.defaultMargin;
    local textSource = context.textSource;
    
    local w = width or 600;
    local h = height or 200;
    
    local minionAssignerWidth = 255;
    --local leftShift = -150;
    
    local g = display.newGroup();
    layer:insert(g);
    newOP.g = g;
    
    local cx, cy = bounds.centerX-0.5*minionAssignerWidth, bounds.centerY;
    
    local btnH = uiConst.defaultBtnHeight;
    local btnW = 3*btnH;
    local btnY = cy + 0.5*h - margin - 0.5*btnH;
    
    local uiUtils = require("ui.uiUtils");
    
    -- add event block
    local eventBlocker =  uiUtils.newTouchEventBlocker(g,context);
    newOP.eventBlocker = eventBlocker;
    
    -- add background
    local back  = uiUtils.newUiBackRect(g, cx,cy , w, h, context,10, true);
    back.alpha = uiConst.uiPaneAlpha;
    newOP.back = back;
    
    -- add text
    self.label  = display.newText{ -- label
        text= textSource:getText(textKey),
        parent = g,
        x = cx,
        y = cy-btnH*0.5,
        width = w - 2* margin,
        height = 0,
        font= uiConst.fontName,
        fontSize = uiConst.normalFontSize,
        align = "center"
    }
    
    self.label:setFillColor(unpack(uiConst.defaultFontColor));
    
    -- add buttons
    
    
    -- add yes button
    if(onYes) then
        newOP.onYes = onYes;
        newOP.yesBtn = context.img:newBtn{dir="ui/actions", name="default",group = g,
            cx =  cx - 0.5*w + margin + 0.5*btnW, cy = btnY,
            w=btnW, h=btnH, hasOver=true,
            onAction = function(event) newOP:onYesBtn() end,
            label = textSource:getText("optionPane.Yes"), labelColor = uiConst.defaultBtnLabelColor, fontSize = uiConst.defaultBtnFontSize 
        }
    end
    
    -- add no button
    if(onNo) then
        newOP.onNo = onNo;
        newOP.noBtn = context.img:newBtn{dir="ui/actions", name="default",group = g,
            cx =  cx + 0.5*w - margin - 0.5*btnW, cy = btnY,
            w=btnW, h=btnH, hasOver=true,
            onAction = function(event) newOP:onNoBtn() end,
            label = textSource:getText("optionPane.No"), labelColor = uiConst.defaultBtnLabelColor, fontSize = uiConst.defaultBtnFontSize 
        }
    end
    
    -- add ok button
    if(onOk) then
        newOP.onOk = onOk;
        newOP.yesBtn = context.img:newBtn{dir="ui/actions", name="default",group = g,
            cx =  cx , cy = btnY,
            w=btnW, h=btnH, hasOver=true,
            onAction = function(event) newOP:onOkBtn() end,
            label = textSource:getText("optionPane.Ok"), labelColor = uiConst.defaultBtnLabelColor, fontSize = uiConst.defaultBtnFontSize 
        }
    end
    -- pop-in
    g.alpha = 0;
    transition.to(g, {alpha=1, time = popTime});
    
end

function OptionPane:onYesBtn()
    
    Runtime:dispatchEvent({name="soundrequest", type="button"}); -- play button sound
    self:removeSelf();
    if(self.onYes) then
        self.onYes();
    end
end

function OptionPane:onNoBtn()
    
    Runtime:dispatchEvent({name="soundrequest", type="button"}); -- play button sound
    self:removeSelf();
    if(self.onNo) then
        self.onNo();
    end
end

function OptionPane:onOkBtn()
    
    Runtime:dispatchEvent({name="soundrequest", type="button"}); -- play button sound
    self:removeSelf();
    if(self.onOk) then
        self.onOk();
    end
end

function OptionPane:removeSelf()
    
    if(self.g == nil) then return; end;
    
    transition.cancel(self.g);
    transition.to(self.g, {alpha=0, time = popTime, onComplete = 
        function()
            self.g:removeSelf();
            self.g = nil;
        end
    });
    
    
end




return OptionPane;


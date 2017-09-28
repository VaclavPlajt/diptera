

local About = {}

local thanksTo = {"Names where removed.", "..."}

function About:new(layer, context)
    
    
    local newAboutUI = {};
    
    setmetatable(newAboutUI, self);
    self.__index = self; 
    
    newAboutUI.layer =layer;
    newAboutUI.context = context;
    newAboutUI.destroyed = false;
    
    
    
    newAboutUI:init();
    
    return newAboutUI;
end


function About:init()
    local bounds = self.context.displayBounds;
    local uiConst = self.context.uiConst;
    local sideMargin = 5*uiConst.defaultMargin;
    local uiUtils = require("ui.uiUtils");
    local textSource = self.context.textSource;
    local titleTextSize = uiConst.hugeFontSize;
    local creditsFontSize = uiConst.bigFontSize;
    local margin = uiConst.defaultMargin;
    local fontColor = uiConst.defaultFontColor;
    --local 
    
    local g  = display.newGroup();
    self.layer:insert(g);
    self.g = g;
    
    local w = bounds.width - 2*sideMargin;
    local h = bounds.height - 2*sideMargin;
    local y = bounds.minY + 0.5*(bounds.height-h);
    
    -- add event blocker
    local eventBlocker = uiUtils.newTouchEventBlocker(g,self.context);
    
    local back = uiUtils.newUiBackRect(g, bounds.centerX, bounds.centerY,w,h, self.context, 10, true);
    back.alpha = 0.6;
    back:addEventListener("tap", function(event) self:hide(); return true; end);
    
    
    local gTitle = display.newGroup();
    g:insert(gTitle);
    
    y = y + margin+0.5*titleTextSize;
    -- add author line
    -- add title
    local titleLabel  = display.newText{
        text= textSource:getText("about.author") .. " Václav Plajt",
        parent = gTitle,
        x = bounds.centerX,
        y = y,
        --width = w,
        font= uiConst.fontName,
        fontSize = titleTextSize,
        align = "center"
    }
    titleLabel:setFillColor(unpack(fontColor))
    --titleLabel.anchorX = 0;
    
    y = y + margin+0.5*titleTextSize;
    local line = display.newLine(gTitle, bounds.centerX-0.5*w+margin, y, bounds.centerX+0.5*w-margin, y);
    line.strokeWidth = 3;
    line:setStrokeColor(unpack(uiConst.clusterEdgeColor));
    line.blendMode = "add";
    
    y = y + line.strokeWidth + 0.5*creditsFontSize + 5*margin;
    
    local gThanks = display.newGroup();
    g:insert(gThanks);
    
    -- add thanks title
    local thanksLabel  = display.newText{
        text= textSource:getText("about.thanks"),
        parent = gThanks,
        x = bounds.centerX,
        y = y,
        --width = w,
        font= uiConst.fontName,
        fontSize = creditsFontSize,
        align = "center"
    }
    thanksLabel:setFillColor(unpack(fontColor));

    
    y = y + 0.5*creditsFontSize + margin;
    local halfThangsTitleWidth = 0.5*(thanksLabel.width)+margin;
    
    line = display.newLine(gThanks, bounds.centerX-halfThangsTitleWidth, y, bounds.centerX+halfThangsTitleWidth, y);
    line.strokeWidth = 1;
    line:setStrokeColor(unpack(uiConst.clusterEdgeColor));
    line.blendMode = "add";
    
    
    y = y + margin + line.strokeWidth+0.5*uiConst.smallFontSize;
    
    local noOrderLabel  = display.newText{
        text= "(" .. textSource:getText("about.no_order") .. ")",
        parent = gThanks,
        x = bounds.centerX,--+0.5*thanksLabel.width,
        y = y,--+0.5*creditsFontSize-0.5*uiConst.smallFontSize,
        --width = w,
        font= uiConst.fontName,
        fontSize = uiConst.smallFontSize,
        align = "left"
    }
    noOrderLabel:setFillColor(unpack(fontColor));
    --noOrderLabel.anchorX =0;
    
    y = y + 0.5*uiConst.smallFontSize + 0.5*creditsFontSize + 2*margin;
    
    local dy = creditsFontSize + margin;
    local personLabels = {};
    
    for i,person in ipairs(thanksTo) do
        local personLabel  = display.newText{
            text= person,
            parent = gThanks,
            x = bounds.centerX,
            y = y,
            --width = w,
            font= uiConst.fontName,
            fontSize = creditsFontSize,
            align = "center"
        }
        personLabel:setFillColor(unpack(fontColor));
        personLabels[#personLabels +1] = personLabel
        
        y= y +dy;
    end
    
    -- copyright notice
    local copyrightNotice  = display.newText{
        text= "© Václav Plajt, 2015",
        parent = g,
        x = bounds.centerX+0.5*w-margin,--+0.5*thanksLabel.width,
        y = bounds.centerY + 0.5*h - 0.5*uiConst.smallFontSize-margin,--+0.5*creditsFontSize-0.5*uiConst.smallFontSize,
        --width = w,
        font= uiConst.fontName,
        fontSize = uiConst.smallFontSize,
        align = "center"
    }
    copyrightNotice:setFillColor(unpack(fontColor));
    copyrightNotice.anchorX = 1;
    
    g.alpha = 0;
    transition.to(g, {alpha =1, time=250});
    
end


function About:hide()
    if(self.destroyed) then return; end;
    
    transition.cancel(self.g);
    transition.to(self.g, {alpha=0, time = 250, onComplete = 
        function()
            self:destroy();
        end
    });
end

function About:destroy()
    if(self.destroyed) then return; end;
    self.destroyed = true;
    
    if(self.g) then
        transition.cancel(self.g);
        self.g:removeSelf();
        self.g = nil;
    end
    
end


return About;




local LanguageSelector ={}

local flagsWidth = 128;
local flagsHeight =  64;
local fadeTime = 250;

local supportedLanguages = 
{
    {
        langCode = "en_us";
        flagFile = "english_flag.png";
        langName = "English"
        --flagHeight =  64;
    },
    {
        langCode = "cs_cz";
        flagFile = "czech_flag.png";
        langName = "Česky"
        --flagHeight =  86;
    }
}


function LanguageSelector:new(layer, context, onLanguageSelected)
    
    local newLanguageSelector = {};
    
    -- set meta tables so lookups will work
    setmetatable(newLanguageSelector, self)
    self.__index = self;
    
    newLanguageSelector.context = context;
    newLanguageSelector.layer= layer;
    newLanguageSelector.onLanguageSelected = onLanguageSelected;
    
    newLanguageSelector:init();
    
    
    return newLanguageSelector;
end

function LanguageSelector:init()
    
    local bounds = self.context.displayBounds;
    local uiConst = self.context.uiConst;
    local uiUtils = require("ui.uiUtils");
    --local textSource = self.context.textSource;
    --local titleTextSize = uiConst.hugeFontSize;
    local fontSize = uiConst.normalFontSize;
    local margin = uiConst.defaultMargin;
    local betweenFlagsMargin = 3*margin;
    local fontColor = uiConst.defaultFontColor;
    
    --local 
    local g  = display.newGroup();
    self.layer:insert(g);
    self.g = g;
    
    local w = #supportedLanguages*(flagsWidth+betweenFlagsMargin) + betweenFlagsMargin;
    local h = margin + flagsHeight + fontSize + 2*betweenFlagsMargin;
    --local y = bounds.centerY;
    
    
    -- add event blocker
    --local eventBlocker = 
    uiUtils.newTouchEventBlocker(g,self.context);
    
    local back = uiUtils.newUiBackRect(g, bounds.centerX, bounds.centerY,w,h, self.context, 10, true);
    back.alpha = 0.6;
    
    local flagY = bounds.centerY -0.5*h+betweenFlagsMargin+0.5*flagsHeight;
    local labelY = flagY + 0.5*flagsHeight+margin+0.5*fontSize+0.5*uiConst.defBtnStrokeWidth;
    local x = bounds.centerX -0.5*w + betweenFlagsMargin + 0.5*flagsWidth;
    local dx = flagsWidth + betweenFlagsMargin;
    
    for index, langDef in ipairs(supportedLanguages) do
        
        -- add flag
        local flag = display.newImageRect(g, "img/ui/" .. langDef.flagFile, flagsWidth, flagsHeight);
        flag.x = x;
        flag.y = flagY;
        flag:addEventListener("tap", function(event) self:onFlagTappedSelected(index); return true; end);
        
        local rect = display.newRect(g, x, flagY, flagsWidth, flagsHeight);
        rect:setFillColor(0, 0);
        
        rect.strokeWidth = uiConst.defBtnStrokeWidth;
        --flag:setStrokeColor(0.5, 1);
        rect.stroke = {type="image", filename="img/comm/btn_stroke.png"}
        rect:setStrokeColor(unpack(uiConst.defBtnStrokeColor.default));
        rect.blendMode = "add";
        
        -- add language label
        local langLabel  = display.newText{
            text= langDef.langName;
            parent = g,
            x = x,
            y = labelY,
            --width = w,
            font= uiConst.fontName,
            fontSize = fontSize,
            align = "center"
        }
        langLabel:setFillColor(unpack(fontColor))
        
        x = x + dx;
    end
    
    g.alpha = 0;
    transition.to(g, {alpha =1, time=fadeTime});
    
end


function LanguageSelector:onFlagTappedSelected(index)
    local selectedLang  = supportedLanguages[index];
    --print("Language " .. tostring(selectedLang.langName) .. " selected");
    
    Runtime:dispatchEvent({name="soundrequest", type="button"}); -- play button sound
    
    if(self.onLanguageSelected) then
        self.onLanguageSelected(selectedLang.langCode);
    end
    
    --g.alpha = ;
    transition.cancel(self.g);
    transition.to(self.g, {alpha =0, time=fadeTime, onComplete = 
        function()
            self:destroy();
        end
    });
    
end


function LanguageSelector:destroy()
    if(self.g) then
        self.g:removeSelf();
        self.g = nil;
    end
end






return LanguageSelector;

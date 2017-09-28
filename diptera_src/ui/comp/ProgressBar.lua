


local ProgressBar = {}
local ceil = math.ceil;

function ProgressBar:new(layer, top, left, h, w,showLabel, maxValue, context)
    
    local o = {};
    -- set meta tables so lookups will work
    setmetatable(o, self);
    self.__index = self;
    
    local g = display.newGroup();
    layer:insert(g);
    o.g = g;
    
    local vertical;
    if(h > w) then
        vertical = true;
    else
        vertical = false;
    end
    
    o.left = left;
    o.top = top;
    o.h = h;
    o.w = w;
    
    local uiConst = context.uiConst;
    
    local fontSize = uiConst.smallFontSize;
    local backColor = uiConst.progressBackColor;
    local color = uiConst.progressColor;
    local textColor = {1};
    --local startColor = {1,0,0,1};
    --local endColor = {0,1,0,1};
    
    -- calc center coordinates
    local cx = left + w*0.5;
    local cy = top + h*0.5;
    
    -- add background image
    --local background = display.newImageRect(g,"ui/img/progress_back50.png", w-h*0.5, h);
    local background = display.newRect(g, cx, cy, w, h);
    background:setFillColor(unpack(backColor));
    o.background = background;
    
    
    
    -- progress indicator
    local progressIndicator = display.newRect( g, cx, cy, w ,h);
    progressIndicator:setFillColor(unpack(color));
    
    local indicatorMaxLength;
    if(vertical) then
        progressIndicator.anchorY = 1;
        indicatorMaxLength = h;
        o.lengthProperty = "height";
        progressIndicator.y = top + h;
    else
        progressIndicator.anchorX = 0;
        indicatorMaxLength = w;
        o.lengthProperty = "width";
        progressIndicator.x = left;
    end
    
    o.indicatorMaxLength = indicatorMaxLength;
    --[[
    progressIndicator.fill =
    { 
        type="image", 
        filename ="ui/img/progress_tex32.png"
    }]]
    
    o.progressIndicator = progressIndicator;
    
    -- progress displaying
    --print(tostring(indicatorMaxLength), tostring(maxValue))
    o:setMaxValue(maxValue);
    
    
    
    -- add label
    if(showLabel) then
        local label = display.newText{parent=g, text="0/" .. maxValue, 
            x=cx, y=cy,
            font=uiConst.fontName, fontSize = fontSize,
        align="center"};
        o.label = label;
        label:setFillColor( unpack(textColor))
    end
    
    
    return o;
end

-- setMaxValue(maxValue, formating)
-- formating - optional formating flag ("%")
function ProgressBar:setMaxValue(maxValue, formating)
    local valueToLenght = self.indicatorMaxLength/maxValue;
    self.valueToLenght = valueToLenght;
    self.maxValue = maxValue;
    self.formating = formating;
end

function ProgressBar:setValue(value)
    --print("function ProgressDisplay:setProgress(value)");
    if(value > self.maxValue) then
        value = self.maxValue;
    elseif( value < 0) then
        value = 0;
    end

    if(self.label) then
        if(self.formating and self.formating == "%")then            
            self.label.text = ceil(value*100) .. " % "-- .. self.maxValue;
        else
            self.label.text = value .. " / " .. self.maxValue;
        end
    end
    
    local pLength = self.valueToLenght *  value;
    if(pLength > 0) then
        self.progressIndicator[self.lengthProperty] = pLength;
        self.progressIndicator.isVisible = true;
    else
        self.progressIndicator[self.lengthProperty] = 1;
        self.progressIndicator.isVisible = false;
    end
    
end


function ProgressBar:removeSelf()
       
    if(self.g) then
        self.g:removeSelf()
        self.g = nil;
    end
    
end

return ProgressBar;


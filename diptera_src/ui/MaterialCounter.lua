
local MaterialCounter = {};

function MaterialCounter:new(context, layer)
    
    local newCounter = {};
    
    -- set meta tables so lookups will work
    setmetatable(newCounter, self)
    self.__index = self;
    
    newCounter.context = context;
    
    newCounter:init(context,layer);
    
    newCounter.countChangedListener =  function(event) newCounter:onCountChanged(event) end;
    Runtime:addEventListener("infoevent", newCounter.countChangedListener);
    
    return newCounter;
    
end

function MaterialCounter:init(context,layer)
    local uiConst = context.uiConst;
    local bounds = context.displayBounds;
    local margin = uiConst.defaultMargin;
    
    local iconSize = 50;
    local labelWidth = 80;
    --local r = 5;
    local h = iconSize;
    local w = iconSize + labelWidth + 2*margin;
    local left = bounds.minX;
    local cy = bounds.maxY - uiConst.aMHeight - 0.5*h;
    
    self.w = w;
    self.h = h;
    self.cy = cy;
    self.left = left;
    
    local g = display.newGroup();
    layer:insert(g);
    self.g = g;
    
    -- add back
    local uiUtils = require("ui.uiUtils");
    --(group, x,y,w,h, context, r, addBorder)
    local back  = uiUtils.newUiBackRect(g, left+0.5*w, cy, w, h, context, nil, false);
    -- add icon
    local icon = display.newImageRect(g, "img/material/mat_100.png", iconSize, iconSize);
    icon.x = left + 0.5*iconSize + margin;
    icon.y = cy;
    
    -- add count label
    local countLabel = display.newText{parent = g,text="0",
        x=left + iconSize + margin + 0.5*labelWidth, y=cy, 
        --width=compW, -- not a multiline text
        --height=h,
        align = "center",
        font=uiConst.fontName,fontSize=uiConst.normalFontSize
    };
    countLabel:setFillColor(unpack(uiConst.defaultFontColor))
    countLabel.blendMode = "add";
    g:insert(countLabel);
    self.countLabel = countLabel;
end

function MaterialCounter:onCountChanged(event)
    
    if(event and event.info == "matCount") then
        --print("material count changed: " .. tostring(event.count));
        local count = event.count;
        self.countLabel.text = tostring(count);
    end
end


function MaterialCounter:destroy()
    
    if(self.g) then
        self.g:removeSelf()
        self.g = nil;
    end
    
    Runtime:removeEventListener("infoevent", self.countChangedListener);
end

return MaterialCounter;

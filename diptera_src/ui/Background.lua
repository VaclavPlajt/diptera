
local Background = {}


function Background:new(layer, context)
    
    
    local newBack = {};
    
    -- set meta tables so lookups will work
    setmetatable(newBack, self);
    self.__index = self;
    
    
    local uiConst = context.uiConst;
    --[[
    local bounds = context.displayBounds;
    local rect = display.newRect(layer, bounds.centerX , bounds.centerY, bounds.width, bounds.height);
    
    rect.fill = {
        type = "gradient",
        color1 = uiConst.backgroundBottomColor,
        color2 = uiConst.backgroundTopColor,
        direction = "up"
    }
    ]]
    self:fromColorArray(layer, context, 
        --{uiConst.backgroundTopColor,{0.2,0.5,0.1},{0.55,0.4,0.65}, uiConst.backgroundBottomColor}
        --{uiConst.backgroundTopColor, uiConst.backgroundBottomColor}
        --{{0.909,0.538,0.199},{0.72,0.591,0.206},{0.307, 0.641,0.758},{0.118,0.32,0.391},{0.118,0.32,0.39}}
        
        --{{0.85,0.497,0.127},{0.476,0.574,0.412},{0.093,0.478,0.611}}
        --{{0.85,0.497,0.127},{0.412,0.573,0.536},{0.093,0.478,0.611}}
        --{uiConst.backgroundTopColor,{0.412,0.573,0.536},{0.093,0.478,0.611}}
        --{{0.851,0.531,0.129},{0.412,0.573,0.536},{0.093,0.478,0.611}}
        --{{0.851,0.531,0.129},{0.412,0.573,0.536},uiConst.backgroundBottomColor}
        
        --{uiConst.backgroundTopColor,{0.412,0.573,0.536},{0.093,0.478,0.611}}
        {uiConst.backgroundTopColor,{0.412,0.573,0.536},uiConst.backgroundBottomColor}
        --{{0.851,0.531,0.129},uiConst.backgroundBottomColor}
    )   
      
    
    --newBack.backRect = rect;
    
    --rect.fill.effect = "filter.vignette";
    --rect.fill.effect.radius = 0.8;
    
    --newBack:addBackscape(layer, context)
    
    return newBack;
end

function Background:fromColorArray(layer, context, colors)
    
    local bounds = context.displayBounds;
    
    local numOfsegments = #colors-1;
    local segmentH = math.floor(bounds.height / numOfsegments);
    local mod = bounds.height-segmentH*numOfsegments;
    local cy = bounds.minY + segmentH*0.5;
    
    --print("mod:" .. mod)
    
    for i=1,numOfsegments do
        local rect = display.newRect(layer, bounds.centerX , cy, bounds.width, segmentH);
    
    rect.fill = {
        type = "gradient",
        color1 = colors[i],
        color2 = colors[i+1],
        direction = "down"
    }
    
    cy = cy + segmentH;
    
    end
    
end

--[[
function Background:addBackscape(layer, context)
    
    local bounds = context.displayBounds;
    local uiConst = context.uiConst;
    local mask = graphics.newMask("img/comm/mm_stripes_mask.png")
    local maskSize = 64;
    
    local c = uiConst.backgroundTopColor;
    local o = 0.6;
    
    local gradient= {
        type = "gradient",
        color1 = uiConst.backgroundBottomColor,
        color2 = {c[1]*o, c[2]*o,c[3]*o},
        direction = "up"
    }
    
    local x,y = bounds.minX+bounds.width*0.15, bounds.minY+bounds.height*0.1;
    local h,w  = bounds.height*0.5, bounds.width*0.55;
    
    local m1 = display.newPolygon(layer, x,y+0.5*h, {0,0,w*0.5,h,-0.5*w,h});
    m1.fill = gradient;
    m1:setMask(mask);
    m1.maskScaleX = w/maskSize;
    m1.maskScaleY = h/maskSize;
    
    m1.blendMode = "multiply"
    
    local cic = display.newCircle(layer, x, y, 5)
    cic:setFillColor(0.9,0.1,0.1);
    cic.alpha = 0.5;
end
]]


return Background;


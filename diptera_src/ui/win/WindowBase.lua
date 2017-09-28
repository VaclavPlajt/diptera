
local WindowBase = {}

-- params: context, layer, contentW, contentH, decoration, cx, cy, top, left, theme
-- either cx, cy or top, left have to be specified
function WindowBase:new(params)
    
    local newWindowBase = {}; -- create new object
    
    -- set meta tables so lookups will work
    setmetatable(newWindowBase, self)
    self.__index = self
    
    newWindowBase:initWindow(params);
    
    return newWindowBase;
end

function WindowBase:initWindow(params)
    
    local contentW = params.contentW;
    local contentH = params.contentH;
    local cx = params.cx or params.left + 0.5*contentW;
    local cy = params.cy or params.top + 0.5*contentH;
    
    
    if(not (cx and cy)) then
        error("WindowBase: either cx, cy or top, left have to be specified !");
    end
    
    -- add cointaining group
    local g = display.newGroup();
    params.layer:insert(g);
    self.g = g;
    
    -- add background rectangle
    local backRect =  display.newRect(g, cx, cy, contentW, contentH);
    backRect:setFillColor(0.1, 1);
    
    
    -- add decoration
    if(params.decoration) then
        local img =params.context.img;
        local decorDef = params.theme.windowDecoration;
        local decW =  decorDef.width;
        
        -- right side decoration
        local rDecCx = cx + 0.5*contentW + 0.5*decW;
        local rDecEndCy = cy - 0.5*contentH - 0.5*decW;
        
        local sideRdec = img:newImg{cx=rDecCx, cy = cy, dir = decorDef.dir, w=decW, h=contentH, name=decorDef.sideDecor};
        local endRdec = img:newImg{cx=rDecCx, cy = rDecEndCy, dir = decorDef.dir, w=decW, h=decW, name=decorDef.endDecor};
        
        -- bottom side decoration
        local bDecCy = cy + 0.5*contentH + 0.5*decW;
        local bDecEndCx = cx - 0.5*contentW - 0.5*decW;
        
        local sideBDec = img:newImg{cx=cx, cy = bDecCy, dir = decorDef.dir, w=decW, h=contentW, name=decorDef.sideDecor};
        sideBDec.rotation = -90;
        
        local endBdec = img:newImg{cx=bDecEndCx, cy = bDecCy, dir = decorDef.dir, w=decW, h=decW, name=decorDef.endDecor};
        endBdec.rotation = -90;
        
        -- corner decoration
        local cornerDec = img:newImg{cx=rDecCx, cy = bDecCy, dir = decorDef.dir, w=decW, h=decW, name=decorDef.cornerDecor};
    
    
    end
    
end






return WindowBase;


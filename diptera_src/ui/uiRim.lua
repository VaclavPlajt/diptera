

local uiRim = {};




function uiRim:init(layer, context, uiMetaInfo)
    
    -- get material counter position
    local mcw,mch,mctop,mcleft = uiMetaInfo:getUIPosition("materialCounter");
    
    -- get action menu position
    local aw,ah,atop,aleft = uiMetaInfo:getUIPosition("actionMenu");
    
    -- get minion assigner position
    local mw,mh,mtop,mleft = uiMetaInfo:getUIPosition("minionAssigner");
    
    -- add rim
    local rim = display.newLine(layer, mcleft, mctop, mcleft+mcw,mctop, mcleft+mcw, atop, mleft, atop, mleft, mtop, mleft+mw, mtop);
    rim.strokeWidth = 16;
    --rim:setStrokeColor(0, 1);
    rim.stroke = {type="image", filename="img/comm/rim_stroke.png"}
    rim.blendMode = "multiply";
    self.rim = rim;
    
    return self;
end


function uiRim:destroy()
    if(self.rim) then
        self.rim:removeSelf();
        self.rim = nil;
    end
end





return uiRim;


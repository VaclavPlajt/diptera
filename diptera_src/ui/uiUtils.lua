
local uiUtils = {}

local textureSize = 128;
uiUtils.listTransitions = {};
uiUtils.lastTransitionId = 0;
--print("INIT     uiUtils")

function uiUtils.mapBackground(layer, isoGrid, uiConst)

    
    local textureSize = uiConst.mapBackTextureSize;
    display.setDefault( "textureWrapX", "repeat" )
    display.setDefault( "textureWrapY", "repeat" )
    
    local back = display.newPolygon(layer, isoGrid.centerX, isoGrid.centerY, 
    {isoGrid.minX, isoGrid.centerY, isoGrid.centerX, isoGrid.minY, isoGrid.maxX, isoGrid.centerY, isoGrid.centerX, isoGrid.maxY}
    );
    
    back.fill = {type="image", filename= "img/back.png"}
    --back:setFillColor(0.5,0.5)
    --local s = textureSize/isoGrid.width; print("W: " .. isoGrid.width .. ", S:" .. s .. "repeated:" .. 1/s .." times")
    
    back.fill.scaleX = textureSize/isoGrid.width;
    back.fill.scaleY = textureSize/isoGrid.height;
    
    back.blendMode = "add";
    back.alpha = uiConst.mapBackgroundAlpha;-- 0.4;
    
    display.setDefault( "textureWrapX", "clampToEdge" )
    display.setDefault( "textureWrapY", "clampToEdge" )
    
    -- add ground thickness
    local t = isoGrid.tileW*0.1; -- thickness in content px
    local wp =  0.5*isoGrid.width;
    local hp =  0.5*isoGrid.height;
    local dirX, dirY = 0.894427, 0.447214;-- normalized left bottom edge direction vector. normalize({1,0.5}), http://www.wolframalpha.com/input/?i=normalize+{1%2C0.5}
    local offset = math.min(isoGrid.tileW*0.25, isoGrid.width*0.01);
    local p = display.newPolygon(layer, isoGrid.centerX, isoGrid.centerY + 0.5*(hp+1+dirY*offset),
    {
    -wp+offset*dirX, 0+offset*dirY, 0, hp  ,  wp-offset*dirX, 0+offset*dirY, -- upper wertextes
      wp-offset*dirX, 0+offset*dirY+t*2, 0, hp+1  ,-wp+offset*dirX, 0+offset*dirY+t*2,-- lower wertextes
    
    }
    --[[{
    isoGrid.minX, isoGrid.centerY, isoGrid.centerX, isoGrid.maxY, isoGrid.maxX, isoGrid.centerY, -- upper wertextes
    isoGrid.maxX, isoGrid.centerY-t, isoGrid.centerX, isoGrid.maxY-t, isoGrid.minX, isoGrid.centerY-t,  -- upper wertextes
    }]]
    );
    
    p:setFillColor(0.1,0.5)
    --p.fill = {type="image", filename="img/comm/map_shadow.png"};
    p.blendMode = "multiply";
    
    return back;
end

function uiUtils.newUiBackRect(group, x,y,w,h, context, r, addBorder)

    display.setDefault( "textureWrapX", "repeat" )
    display.setDefault( "textureWrapY", "repeat" )
    
    local back;
    if(r) then
        back = display.newRoundedRect(group, x, y, w,h, r);
    else
        back = display.newRect(group, x, y, w,h);
    end
    
    
    back.fill = {type="image", filename = "img/ui/back_noise.png"};
    
    local f = back.fill;
    f.scaleX = textureSize/w;
    f.scaleY = textureSize/h;
    f.x = 0;
    f.y = 0;
    if(addBorder) then
        back.strokeWidth = 16;
        back.stroke = {type="image", filename="img/comm/win_stroke.png"}
    end
    --back:setFillColor(0.1,0,0.2,self.uiConst.uBackAlpha);
    --back:setFillColor(0.1,0,0.2,1);
    back.alpha = context.uiConst.uiBackAlpha;
    
    display.setDefault( "textureWrapX", "clampToEdge" )
    display.setDefault( "textureWrapY", "clampToEdge" )
    
    return back;
end


function uiUtils.newTouchEventBlocker(group,context)
    
    local bounds = context.displayBounds;
    
    local eventBlocker =  display.newRect(group, bounds.centerX, bounds.centerY, bounds.width, bounds.height);
    eventBlocker:setFillColor(0.5,0.5,0.5, 0.5);
    eventBlocker:addEventListener("touch", function() return true end);
    eventBlocker:addEventListener("tap", function() return true end);
    --eventBlocker.blendMode = "srcOver";
    --eventBlocker.isVisible = false;
    return eventBlocker;
end

function uiUtils.recalcFillScale(rectangle, newWidth, newHeight)
    
    local w = newWidth or rectangle.width;
    local h = newHeight or rectangle.height;
    
    local f = rectangle.fill;
    f.scaleX = textureSize/w;
    f.scaleY = textureSize/h;
    --f.x = 0;
    --f.y = 0;
    --return textureSize/w, textureSize/h;
end


function uiUtils.cancelTransitionList(id)
    
    if(uiUtils.listTransitions[id]) then
        transition.cancel(uiUtils.listTransitions[id])
        uiUtils.listTransitions[id] = nil;
    end
    
end

function uiUtils.followPathTransition(displayObject, path, speed,  repetitionCount, transition)
    
    local transList ={};
    local distFc = require("math.geometry").chebyshevDist;--( x1, y1, x2, y2 )
    local floor = math.floor;
    displayObject.x = path[1];
    displayObject.y = path[2];
    
    for i=3, #path,2 do
        local dist = distFc(path[i-2], path[i-1],path[i], path[i+1]);
        local t = floor(1000*dist/speed);
        --print("dist: " .. dist .. ", t:" .. t);
        
        transList[#transList + 1] = {x=path[i], y=path[i+1], time = t, transition=transition}
    end
    
    if(repetitionCount and repetitionCount ~= 0) then
        local dist = distFc(path[1], path[2],path[#path-1], path[#path]);
        local t = 1000*dist/speed;
        transList[#transList + 1] = {x=path[1], y=path[2], time =t, transition=transition};
    end
    
    return uiUtils.startTransitionList(displayObject, transList, repetitionCount);
end


function uiUtils.startTransitionList(displayObject, optionsList, repetitionCount)
    
    local id = uiUtils.lastTransitionId +1;--#(uiUtils.listTransitions)+1;
    uiUtils.lastTransitionId = id;
    local params = {index = 1, list=optionsList, repetitionCount = repetitionCount or 1, count=1, id=id};
       
        
    uiUtils.doNextTransition(displayObject, params);
    return id;
end

function uiUtils.doNextTransition(displayObject, params)
    
    
    local doNext = false;
    local addCalback = false;
    local index = params.index;
    local options = params.list[index];
    
    if(params.count == 1) then addCalback = true; end;
    
    if(index == 1 and params.repetitionCount > 0 and params.count > params.repetitionCount) then
        uiUtils.listTransitions[params.id] = nil;
        return;
    end
    
    if(index == #params.list) then -- repeat ?
        
        params.count = params.count +1;
        params.index = 1;
        
       if(params.repetitionCount > params.count or params.repetitionCount < 0) then
           doNext= true;   
       end
   else
       params.index = index +1;
       doNext= true;
   end
    
    -- add calback
    if(doNext and addCalback)then
        local inputOnComplete =  options.onComplete;
        if(inputOnComplete)then 
            -- user passed in its own onComplete function,
            -- lets respect it
            
            options.onComplete = 
            function()
                inputOnComplete();
                uiUtils.doNextTransition(displayObject, params);
            end
            
        else
            options.onComplete = function() uiUtils.doNextTransition(displayObject, params); end;
        end
    end
    
    uiUtils.listTransitions[params.id] = transition.to(displayObject, options);
end


function uiUtils.setShapePolyStyle(shapePoly, aiStyle, uiConst)
    
    if(aiStyle) then
        --color = self.context.uiConst.aiPlayerColor;
        shapePoly:setFillColor(unpack(uiConst.aiPlayerColor));
        --shapePoly.blendMode = "normal";
        shapePoly.blendMode = "multiply";
        shapePoly.alpha = 0.8;
    else
        --color = self.context.uiConst.humanPlayerColor;
        shapePoly:setFillColor(unpack(uiConst.humanPlayerColor));
        shapePoly.blendMode = "add";
        shapePoly.alpha = 1; 
    end
end


function uiUtils.newArrowPointer(layer,uiConst, x,y)
    local w = 150;
    local h = 50;
    
    local b = 0.35*h;
    local a = (h-b)*0.5;
    local wp = w*0.4;
    
    --local arrow = display.newPolygon(layer, x,y, {0,0,-wp,-0.5*h,-wp,-0.5*h+a,-w,-0.5*b,-w,0.5*b,-wp, 0.5*h-a,-wp, 0.5*h} );
    local arrow = display.newPolygon(layer, x,y, {0,0,-wp,-0.5*h,-wp,-0.5*h+a,-w,-0.4*h,-w+b,0,-w,0.4*h,-wp, 0.5*h-a,-wp, 0.5*h} );
    
    arrow:setFillColor(unpack(uiConst.arrowPointerFillColor))
    arrow.stroke = {type="image", filename="img/comm/btn_stroke.png"}
    arrow:setStrokeColor(unpack(uiConst.arrowPointerStrokeColor));
    arrow.strokeWidth = uiConst.defBtnStrokeWidth;
    arrow.blendMode ="add";
    
    arrow.anchorX = 1;
    --transition.to(arrow,{rotation=360, time = 3000})
    
    return arrow;
end

return uiUtils;


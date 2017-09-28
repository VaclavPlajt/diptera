

local minionAssigner = {}


local btnsDir = "ui/actions";
local transName = "highTrans";

function minionAssigner:init(context, layer)
    
    self.context = context;
    self.layer = layer;
    
    
    --self.uiConst = context.uiConst;
    local uiConst =  context.uiConst;
    local bounds = context.displayBounds;
    
    -- dimensions
    local margin = uiConst.defaultMargin;
    local rowNames = require("game.gameConst").minionWorkTypes;
    self.rowNames = rowNames;
    local rowIcons = {"rep_rsqt.png", "work_rqst.png", "transport_icon.png"};--{"repair_icon.png", "work_icon.png", "transport_icon.png"};
    local btnSize = uiConst.mAssignerBtnSize;
    local titleH =  uiConst.mAssignerFonSize*1.2;
    local rowH = titleH + btnSize;
    local rowMargin = 1.5*margin;
    local idleRowH = titleH;
    local h = rowH*(#rowNames-1)+rowMargin*(#rowNames-1) + idleRowH + 6*margin;
    local w = 4*btnSize+3*margin;
    local left = bounds.maxX -  w;
    local top  = bounds.maxY - h - uiConst.aMHeight;
    
    self.w = w;
    --print("MA W:" .. w)
    self.h= h;
    self.left = left;
    self.top = top;
    
    -- create group
    local g = display.newGroup();
    self.layer:insert(g);
    self.g = g;
    
    -- add background
    self:addBackground(left,top,w,h);
    
    -- add rows
    self:addRows(left, top, w,h,context, uiConst, rowNames,rowIcons, rowH, titleH, uiConst.mAssignerFonSize, rowMargin);
    
    -- add highlight arrow
    local uiUtils = require("ui.uiUtils");
    local arrowCy = top+0.5*h;
    self.arrow = uiUtils.newArrowPointer(g,uiConst, left-margin,arrowCy);
    self.arrow.isVisible = false;
    --self.arrow.alpha = 1;
    --self.arrow.blendMode = "normal";
    self.arrowMinX = self.arrow.x - 200;
    self.arrowMaxX = self.arrow.x;
    self.arrowCy = arrowCy;
    
    -- register listener to "minionAssigmentChanged" event
    self.assignChangedListener = function(event) self:onAssigmentChanged(event) end;
    Runtime:addEventListener("minionAssigmentChanged", self.assignChangedListener);
    
    
    return self;
end

function minionAssigner:destroy()
    
    self:stopHighlight();
    
    if(self.assignChangedListener) then
        Runtime:removeEventListener("minionAssigmentChanged", self.assignChangedListener);
        self.assignChangedListener = nil;
    end
    
    if(self.g) then
        self.g:removeSelf();
        self.g = nil;
    end
    
end

function minionAssigner:addBackground(left,top,w,h)
    
    
    local uiUtils = require("ui.uiUtils");
    local back  = uiUtils.newUiBackRect(self.g, left+0.5*w, top+0.5*h,w,h, self.context);
    self.back =back;
    
    back:addEventListener("touch", function() return true end)
    back:addEventListener("tap", function() return true end)
end


function minionAssigner:addRows(left, top, w,h,context, uiConst, rowNames,rowIcons, rowH, titleH, fontSize, rowMargin)
    
    local margin = uiConst.defaultMargin;
    local btnSize = uiConst.mAssignerBtnSize;
    --print("minionAssigner button size: " .. btnSize)
    local rowComponentWidhts = {desc = w, icon = btnSize, count = btnSize, plus = btnSize, minus = btnSize}
    
    local rowW = w;
    local rowTop = top+margin;
    local labelPrefix = "mAssigner."
    self.rowGroups = {};
    self.rowsCy = {};
    self.rowCountLabels = {};
    self.rowCounts = {};
    self.plusBtns = {};
    self.minusBtns = {};
    
    
    for i=1, #rowNames do
        local name = rowNames[i];
        local labelKey = labelPrefix .. name;
        local label = context.textSource:getText(labelKey);
        self:addAssigningRow(left, rowTop, rowW, rowH, name,label, context.img, rowComponentWidhts,uiConst,i, titleH, fontSize, rowIcons[i]);
        --local cLine = display.newLine(left, rowTop, left +rowW, rowTop);
        
        rowTop = rowTop + rowH+2*rowMargin;
        
    end
    
end

function minionAssigner:addAssigningRow(left, top, w, h, name, label, img, componentWidhts,uiConst, index, titleH, fontSize, iconName)
    -- create row group
    local g = display.newGroup();
    self.g:insert(g);
    self.rowGroups[index] =g;
    local margin = uiConst.defaultMargin;
    local labelColor = uiConst.defaultBtnLabelColor;
    
    local cy;
    if(name == "idle") then
        cy = top + margin + 0.5*(titleH-margin);
    else
        cy = top + titleH+margin + 0.5*(h-titleH-margin);
    end
    
    self.rowsCy[index] = cy;
    
    local x = left+margin;
    local compW;
    
    
    compW = componentWidhts.desc;
    
    -- add descripion text
    local titleY;
    if(name == "idle") then
        titleY = cy;
    else
        titleY = top+titleH*0.5;
    end
    
    local titleText = display.newText{parent = g,text=label,
        x=x, y=titleY, 
        --width=compW, -- not a multiline text
        --height=h,
        align = "left",
        font=uiConst.fontName,fontSize=fontSize
    };
    titleText.anchorX = 0;
    --titleText.x = 
    titleText:setFillColor(unpack(uiConst.defaultFontColor))
    titleText.blendMode = "add";
    --titleText:setFillColor(unpack(uiConst.highlightedFontColor))
    
    -- add title background to increase redeability
    local titleBack = display.newRect(g, left+0.5*(w), titleY-0.5*margin, w, titleH+margin, margin);
    --titleBack:setFillColor(0.2, 0.75);
    --titleBack.blendMode = "multiply";
    titleBack.fill = {
        type = "gradient",
        color1 = { 0,0,0,0.4},
        color2 = { 0,0,0,0.0},
        direction = "right"
    }
    
    g:insert(titleText);
    
    --x = x + compW;
    x = left+margin;
    compW = componentWidhts.icon;
    
    if(name ~= "idle") then -- idle row has no icon
        local icon;
        if(iconName) then
            icon = display.newImageRect(self.g, "img/comm/" .. iconName , compW,compW);
            icon.x =x+0.5*compW; icon.y=cy;
            --icon.blendMode = "add";
            --icon:setFillColor(unpack(uiConst.humanPlayerColor));
            --icon.blendMode = "add";
        else
            print("No icon for .." .. name);
            --icon = display.newRect(self.g, x+0.5*compW, cy, compW,compW);
            --icon:setFillColor(0.4,0,0.2);
            
        end
    end
    
    x = x + compW + margin;
    
    compW = componentWidhts.minus;
    if(name ~= "idle") then -- idle row has no buttons
        -- add minus button
        local minusBtn = img:newBtn{dir=btnsDir, name="btn_back", group=g,
            cx=x+0.5*compW, cy = cy, hasOver = true, label = "-",
            labelColor=labelColor, fontSize=uiConst.hugeFontSize,
            onAction=function(event)
                self:onMinusBtnAction(event, name);
            end,
        w=compW, h=compW};
        self.minusBtns[name] = minusBtn;
    end
    
    x = x + compW;
    
    --[[
    if(name == "idle") then
        x =x + compW; -- shift count label
    end
    ]]
    
    -- add count label text
    compW = componentWidhts.count;
    local countLabel = display.newText{parent = g,text="0",
        x=x + 0.5* compW, y=cy, 
        --width=compW, -- not a multiline text
        --height=h,
        align = "center",
        font=uiConst.fontName,fontSize=uiConst.bigFontSize
    };
    countLabel:setFillColor(unpack(uiConst.defaultFontColor))
    countLabel.blendMode = "add";
    g:insert(countLabel);
    
    x = x + compW;
    self.rowCountLabels[name] = countLabel;
    self.rowCounts[name] = 0;
    
    if(name ~= "idle") then -- idle row has no buttons
        compW = componentWidhts.plus;
        -- add plus button
        local plusBtn = img:newBtn{dir=btnsDir, name="btn_back", group=g ,
            cx=x+0.5*compW, cy = cy,  hasOver = true,
            label = "+", labelColor=labelColor,  fontSize= uiConst.hugeFontSize,
            onAction=function(event)
                self:onPlusBtnAction(event, name);
            end,
        w=compW, h=compW};
        self.plusBtns[name] = plusBtn;    
    end
    
end

-- chane assigement request:
--* "minionAssigmentRequest" - braodcasted when user inputs request to chnge minion assigments
--    -   change - "add"/"remove" - ad or remove minion from work type assigment
--    -   workType - work type name
function minionAssigner:onPlusBtnAction(event, btnName)
    --print("onPlusBtnAction() :" .. btnName)
    
    local idleCount = self.rowCounts["idle"];
    if(idleCount <= 0) then
        --print("No idle minion to assign.");
        return;
    end
    
    Runtime:dispatchEvent({name="soundrequest", type="button"}); -- play button sound
    Runtime:dispatchEvent{name="minionAssigmentRequest", change="add", workType=btnName }
    
end

function minionAssigner:onMinusBtnAction(event, btnName)
    --print("onMinusBtnAction() :" .. btnName)
    
    local count = self.rowCounts[btnName];
    if(count <= 0) then
        --print("No minion to remove.");
        return;
    end
    
    Runtime:dispatchEvent({name="soundrequest", type="button"}); -- play button sound
    Runtime:dispatchEvent{name="minionAssigmentRequest", change="remove", workType=btnName }
    
end

function minionAssigner:onAssigmentChanged(event)
    
    --print("onAssigmentChanged(event)");
    local labels = self.rowCountLabels;
    if(labels == nil) then
        return;
    end
    
    local assigments = event.assigments;
    
    for workType, count in pairs(assigments) do
        
        local label = labels[workType];
        if(label) then
            label.text = tostring(count);
            self.rowCounts[workType] = count;
            --print("updating " .. workType .. " to count: " .. count);
        end
        
    end
    
    if(event.added and event.added > 0) then
        --print("TODO added minion (".. event.added .. "), animate it !!");
        self:animateMinionAddition(event.added);
    end
    
end

function minionAssigner:animateMinionAddition(count)
    
    local uiConst =  self.context.uiConst;
    local margin = uiConst.defaultMargin;
    local scale = 1.5;
    local scaleDown  = uiConst.bigFontSize/uiConst.hugeFontSize;
    
    local countLabel =  self.rowCountLabels["idle"];
    
    local label = display.newText{
        parent = self.g,
        text="+" .. tostring(count),
        x=0, y=countLabel.y, 
        --width=compW, -- not a multiline text
        --height=h,
        align = "left",
        font=uiConst.fontName,fontSize=uiConst.hugeFontSize
    };
    label:setFillColor(unpack(uiConst.defaultFontColor))
    label.x = countLabel.x + 0.5*countLabel.width+0.5*label.width*scale+margin;
    label.blendMode = "add";
    label.xScale=scaleDown;
    label.yScale=scaleDown;
    --self.g:insert(countLabel);
    
    
    transition.to(label, {xScale = scale, yScale = scale, time = 750,
        --y = label.y - (label.height-labelheight*scale,
        onComplete = 
        function()
            transition.to(label,  { alpha = 0, time = 250, onComplete = 
                function()
                    label:removeSelf();
                end
            });
        end
        
    })
    
end


function minionAssigner:HighUp(f, transName)
    self[transName] = 
    transition.to(f.effect, {intensity = 1.0, time=750, transition=easing.inOutSine, onComplete = 
        function()
            self:HighDown(f, transName);
        end
    });
end

function minionAssigner:HighDown(f, transName)
    self[transName] = 
    transition.to(f.effect, {intensity = 0, time=750, transition=easing.inOutSine, onComplete = 
        function()
            self:HighUp(f, transName);
        end
    });
end

function minionAssigner:arrowBackward()
    transition.to(self.arrow, {x=self.arrowMinX,xScale=1, time=750, onComplete = 
        function()
            self:arrowForward()
        end
    })
end

function minionAssigner:arrowForward()
    transition.to(self.arrow, {x=self.arrowMaxX,xScale=0.8, time=750,
        transition = easing.outSine,
        onComplete = 
        function()
            self:arrowBackward()
        end
    })
end

function minionAssigner:startHighlight(params)
    
    --print("self:startHighlight(params), params: ".. tostring(params));
    
    --local rowIndex = self.rowNames
    local f; -- animated fill
    local cy;
    
    if(params) then
        local btn = self.plusBtns[params];
        --print("btn: btn.numChildren: " .. btn.numChildren);
        
        -- search for shape object inside button group
        for i= 1, btn.numChildren do
            local obj = btn[i];
            if(obj.fill and obj.text==nil) then
                self.highlightedObject = obj;
                f = obj.fill;
                local x,y = obj:localToContent(obj.x, obj.y-0.5*obj.height);
                x,y = self.g:contentToLocal(x,y);
                cy = y;
                break;
            end
        end
        --local rect = display.new
        
    end
    
    if(not f) then
        f = self.back.fill;
        self.highlightedObject = self.back;
    end
    
    self:stopHighlight(transName);
    
    if(f.effect == nil) then
        f.effect = "filter.brightness"; --"filter.contrast";
    end
    f.effect.intensity = 0.0;
    --f.effect.contrast = 1.0;
    
    
    self:HighUp(f, transName);
    local arrow = self.arrow;
    
    arrow.isVisible = true;
    arrow.x = self.arrowMinX;
    arrow.xScale = 1;
    if(cy) then
        arrow.y = cy;
    else
        arrow.y = self.arrowCy;
    end
    
    self:arrowForward();
    
end

function minionAssigner:stopHighlight()
    --print("minionAssigner:stopHighlight()");
    if(self[transName]) then
        transition.cancel(self[transName]);
        --print("Instructions:cancelHighlightLabel(transName) " .. transName)
        if(self.highlightedObject.fill.effect) then
            self.highlightedObject.fill.effect =  nil;    
        end
        self[transName] = nil;
        -- stop arrow
        self.arrow.isVisible = false;
        transition.cancel(self.arrow);
    end
end

--[[
function minionAssigner:showHighlight(rowName, btnType)
    local uiConst =  self.context.uiConst;
    local btnSize = uiConst.mAssignerBtnSize;
    
    
    local rowIndex = 1;
    local btn;
    if(btnType == "plus") then
        btn = self.plusBtns[rowIndex];
    else
        btn = self.minusBtns[rowIndex];
    end
    
    --local rowGroup =self.rowGroups[rowIndex];
    
    if(btn==nil) then
        return;
    end
    
    local cx, cy = btn:localToContent(btn.x, btn.y)--self.rowsCy[rowIndex];
    local cx = btn.y--self.left + 0.5*self.w; --??? x toho spravnyho buttonu ...
    local w = btnSize;
    local h = btnSize;
    
    print("rect x,y:" .. cx .. ", " .. cy);
    
    local rect = display.newRect(self.g, cx, cy, w, h)
end
]]

return minionAssigner;

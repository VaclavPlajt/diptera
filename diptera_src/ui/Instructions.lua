local Instructions = {}


-- instruction  {textKey="string",
--      startDelay= in ms, duration=in ms , 
--      endEvent = string , endEventParams={{key=string, val=value}, ...},
--      startEvent = string , startEventParams={{key=string, val=value}, ...},
--      arrowTarget=string }

function Instructions:new(layer, context,uiMetaInfo, instructionsList)
    
    local newInstructions = {};
    
    -- set meta tables so lookups will work
    setmetatable(newInstructions, self)
    self.__index = self
    
    
    newInstructions.context = context;
    newInstructions.instructions = instructionsList;
    newInstructions.uiMetaInfo = uiMetaInfo;
    newInstructions.currentIndex = 0;
    newInstructions.textSource =  context.textSource;
    
    newInstructions.timer = nil;
    newInstructions.startEventListener = function(event) newInstructions:onStartEvent(event); end;
    newInstructions.endEventListener   = function(event) newInstructions:onEndEvent(event); end;
    newInstructions.endEventName = nil;
    newInstructions.currentInstruction = {};
    --newInstructions.currentArrow = nil;
    
    newInstructions.expandedState = "hidden";
    newInstructions.hideAfterContraction =  false;
    newInstructions.nextAfterContraction = false;
    newInstructions.highlightContracted = false;
    newInstructions.labelTrans = nil;
    --newInstructions.nextInstructionAfterContraction = false;
    newInstructions.highlightedUI = nil;
    
    newInstructions:initGraphics(layer, context)
    
    -- log event to analytics
    --context:analyticslogEvent("Instructions-new");
    
    return newInstructions;
end

function Instructions:initGraphics(layer, context)
    local bounds = context.displayBounds;
    local uiConst = context.uiConst;
    
    local g = display.newGroup();
    layer:insert(g)
    self.g = g;
    
    --self.arrowStrokeWidth = 2;
    
    local qw,qh,qtop, qleft = self.uiMetaInfo:getUIPosition("minionAssigner");--"quickActionsMenu");
    local margin = uiConst.defaultMargin;
    
    local backH = 1*1.3*uiConst.bigFontSize;
    self.backH = backH;
    self.backAlpha = context.uiConst.uiBackAlpha;
    
    --local tipH = uiConst.normalFontSize*1.25;
    --local h = backH + tipH + 3*margin;
    --local cy =bounds.minY+0.5*h;
    local w = bounds.width - qw-3*margin;
    local left = bounds.minX + margin;
    local cx = left + 0.5*w;
    
    local uiUtils = require("ui.uiUtils");
    
    -- add event block
    local eventBlocker =  uiUtils.newTouchEventBlocker(g,context);
    self.eventBlocker = eventBlocker;
    eventBlocker.isVisible = false;
    
    
    -- add background
    local backCy = bounds.minY+margin+0.5*backH;
    self.backCy = backCy;
    
    self.expandedAlpha = uiConst.uiPaneAlpha;
    self.contractedAlpha = uiConst.uiBackAlpha;
    
    self.recalcFillScale =  uiUtils.recalcFillScale;--(rectangle, newWidth, newHeight)
    local back  = uiUtils.newUiBackRect(g, cx, backCy, w, backH, context, 10, true);
    --local back =  display.newRect(g, cx, backCy, w, backH);
    back:addEventListener("tap", function() self:onBackTap() end)
    self.back = back;
    --back:setFillColor(0.6,0.3,0.4, 0.9);
    back.isVisible = false;
    --back.strokeWidth = 16;
    --back.stroke = {type="image", filename="img/comm/win_stroke.png"}
    --back:setStrokeColor(0.6,0.3,0.4, 0.9);
    --back.stroke = {type = "gradient", color1 = {0.6,0.3,0.4, 0.9}, color2 = { 0, 0, 0, 0.0 }, direction = "down"};
    
    
    self.expandedH = 450;
    self.buttonSpaceH = 70;
    self.expandedBackCy = bounds.minY+margin+0.5*self.expandedH;
    self.expandedLabelY = bounds.minY+margin+0.5*(self.expandedH-self.buttonSpaceH - backH);
    self.labelYinExpandedState = bounds.minY+margin+ self.expandedH-self.buttonSpaceH - 0.5*backH;
    self.buttonsH = self.buttonSpaceH - 10;
    self.buttonsW = 3*self.buttonsH;
    self.expandedFontSize = uiConst.hugeFontSize;
    self.contractedFontSize = uiConst.bigFontSize;
    
    
    -- add ok button
    -- creates new 1 or 2-image button
    -- params: {dir= directory name, name=image name, group=display group, top=um, left= num, cx=num, cy = num,
    -- onAction=function(event), w= num, h=num, label=string, labelColor= see widgets docs, fontSize = optional font size, hasOver= boolean}
    -- either 'top' 'left' or 'cx' 'cy' has to be specified
    -- w,h - optional width and height parameters, button is scaled according to size of default image if not supplie
    local okButton = context.img:newBtn{dir="ui/actions", name="default", group=g,
        cx = left + w - margin - 0.5*self.buttonsW, cy = bounds.minY+self.expandedH-0.5*self.buttonsH,
        w=self.buttonsW, h=self.buttonsH, hasOver=true,
        onAction = function(event) self:onOk() end,
        label = "Ok", labelColor = uiConst.defaultBtnLabelColor, fontSize = uiConst.defaultBtnFontSize 
    }
    
    okButton.isVisible = false;
    self.okButton = okButton;
    
    
    self.bounds  = bounds;
    
    -- add main text object
    local labelW = w - 4*margin;
    
    self.label  = display.newText{ -- contracted or tips label
        text= "",
        parent = g,
        x = cx,--left+margin,--cx,
        y = backCy,
        width = labelW,
        height = 0,
        font= uiConst.fontName,
        fontSize = self.contractedFontSize,
        align = "left"
    }
    --self.label.anchorX = 0;
    self.label:setFillColor(unpack(uiConst.highlightedFontColor));
    self.label.isVisible = false;
    
    self.expandedLabel  = display.newText{
        text= "",
        parent = g,
        x = cx,
        y = self.expandedLabelY,
        width = labelW,
        height = 0,--self.expandedH - self.buttonSpaceH - backH,
        font= uiConst.fontName,
        fontSize = self.expandedFontSize,
        align = "center"
    }
    
    --local rect = display.newRect(g, cx, self.expandedLabelY, labelW, self.expandedH);
    --rect.alpha = 0.5;
    
    self.expandedLabel.isVisible = false;
    self.expandedLabel:setFillColor(unpack(uiConst.defaultFontColor));
    
end

function Instructions:forceExpand()
    if(self.expandedState ~= "contracted") then
        self.expandedState = "contracted";
        transition.cancel(self.back);
    end
    
    
    self:expand();
end

function Instructions:expand()
    
    if(self.expandedState ~= "contracted") then return; end;
    self.expandedState = "expanding";
    
    -- resize back of instruction window
    transition.to(self.back, { height = self.expandedH, y = self.expandedBackCy, alpha=self.expandedAlpha, time = 450, onComplete = 
        function()
            self.expandedState = "expanded";
            
            -- pause the game
            Runtime:dispatchEvent{name="actionSelected", action="pauseGame"}
            
            
            -- change back fill scale
            self.recalcFillScale(self.back);
            
            self.okButton.isVisible = true;
            transition.cancel(self.okButton);
            self.okButton.alfa = 0;
            transition.to(self.okButton, {alpha = 1, time = 350})
            
            -- show expanded label text
            self.expandedLabel.isVisible = true;
            self.expandedLabel.alpha = 0;
            transition.cancel(self.expandedLabel);
            transition.to(self.expandedLabel, {alpha = 1, time = 250});
            
            --move and show label
            self.label.y = self.labelYinExpandedState;
            self.label.isVisible = true;
            transition.cancel(self.label);
            --self:cancelHighlightLabel(self.label, "labelTrans");
            transition.to(self.label, {alpha = 1, time = 250});
        end
    })
    
    -- change fill scale
    -- recalc back rectngle fill scale
    --local scaleX, scaleY = self.recalcFillScale(self.back), self.back.width ,self.expandedH);
    --transition.cancel(self.back.fill);
    --transition.to(self.back.fill, {scaleX=scaleX, scaleY=scaleY, time = 450});
    
    -- hide label text
    transition.cancel(self.label);
    self:cancelHighlightLabel(self.label,"labelTrans");
    transition.to(self.label, {alpha = 0, time = 250});
    
    -- show event blocker
    self.eventBlocker.isVisible = true;
    self.eventBlocker.alpha =0;
    transition.cancel(self.eventBlocker);
    transition.to(self.eventBlocker, {alpha = 1, time = 450});
end

function Instructions:contract()
    if(self.expandedState ~= "expanded") then return; end;
    self.expandedState = "contracting";
    
    self.okButton.isVisible = false;
    self.expandedLabel.isVisible = false;
    
    
    -- resize back of instruction window
    transition.to(self.back, { height = self.backH, y = self.backCy, alpha=self.contractedAlpha, time = 450, onComplete = 
        function()
            --self.okButton.isVisible = true;
            self.expandedState = "contracted";
            
            -- change back fill scale
            self.recalcFillScale(self.back);
            
            if(self.nextAfterContraction) then
                self.nextAfterContraction = false;
                self:removeCurrent();
                self:nextInstruction();
                return;
            end
            
            if(self.hideAfterContraction)then
                self.hideAfterContraction = false;
                self:hideUI();
            else
                
                -- show label text
                self.label.y = self.backCy;
                self.label.isVisible = true;
                self.label.alpha = 0;
                transition.cancel(self.label);
                transition.to(self.label, {alpha = 1, time = 250});
                if(self.highlightContracted) then  self:highlightLabel(self.label,"labelTrans"); end;
            end
        end
    })
    
    -- change fill scale
    -- recalc back rectangle fill scale
    local scaleX, scaleY = self.recalcFillScale(self.back, self.back.width ,self.backH);
    transition.to(self.back.fill, {scaleX=scaleX, scaleY=scaleY, time = 450});
    
    -- hide label text
    self:cancelHighlightLabel(self.label,"labelTrans");
    transition.cancel(self.label);
    transition.to(self.label, {alpha = 0, time = 250});
    
    -- hide event blocker
    self.eventBlocker.isVisible = false;
    
    -- resume game
    Runtime:dispatchEvent{name="actionSelected", action="resumeGame"}
end


function Instructions:hideUI()
    
    if(self.expandedState == "hidden") then
        return;
    elseif(self.expandedState == "expanded") then
        self.hideAfterContraction = true;
        self:contract();
    elseif(self.expandedState == "contracted") then
        -- hide label
        transition.cancel(self.label);
        self:cancelHighlightLabel(self.label, "labelTrans");
        transition.to(self.label, {alpha = 0, time =250, onComplete = function() self.label.isVisible = false; end});
        -- hide back
        transition.cancel(self.back);
        transition.to(self.back, {alpha = 0, time =250, onComplete = function() self.back.isVisible = false; end});
        
        self.expandedLabel.isVisible = false;
        self.okButton.isVisible = false;
        
        -- hide event blocker
        self.eventBlocker.isVisible = false;
        
        self.expandedState= "hidden";
    elseif(self.expandedState == "expanding")then
        -- cancel expansion
        transition.cancel(self.back);
        self.expandedState = "expanded";
        self.hideAfterContraction = true;
        self:contract();
    else -- contracting
        self.hideAfterContraction = true;
    end
    
end


function Instructions:showUI()
    
    if(self.expandedState == "hidden") then
        -- show label
        transition.cancel(self.label);
        self.label.isVisible = true;
        self:cancelHighlightLabel(self.label, "labelTrans");
        self.label.alpha = 0;
        transition.to(self.label, {alpha = 1, time =250});
        -- show back
        transition.cancel(self.back);
        self.back.isVisible = true;
        self.back.alpha = 0;
        transition.to(self.back, {alpha = self.backAlpha, time =250});
        
        self.expandedState= "contracted";
        
        --elseif(self.expandedState == "expanded") then
        
        --elseif(self.expandedState == "contracted") then
        
        --elseif(self.expandedState == "expanding")then
        
    elseif(self.expandedState == "contracting") then
        self.hideAfterContraction = false;
        
    end
    
end


function Instructions:HUp(f, transName)
    self[transName] = 
    transition.to(f.effect, {intensity = 1, time=750, transition=easing.inOutSine, onComplete = 
        function()
            self:HDown(f, transName);
        end
    });
end

function Instructions:HDown(f, transName)
    self[transName] = 
    transition.to(f.effect, {intensity = 0, time=750, transition=easing.inOutSine, onComplete = 
        function()
            self:HUp(f, transName);
        end
    });
end


function Instructions:highlightLabel(label, transName)
    
    local f = label.fill;
    --transition.cancel(f);
    --print("Instructions:highlightLabel(label, transName) " .. transName)
    
    self:cancelHighlightLabel(transName);
    
    if(f.effect == nil) then
        f.effect = "filter.brightness";
    end
    
    f.effect.intensity = 0.0;
    
    self:HUp(f, transName);
end


function Instructions:cancelHighlightLabel(label, transName)
    --local f = label.fill;
    --transition.cancel(f);
    --print("pre cancel: " .. transName .. ", self[transName]:" .. tostring(self[transName]) );
    if(self[transName]) then
        transition.cancel(self[transName]);
        --print("Instructions:cancelHighlightLabel(transName) " .. transName)
        if(label.fill.effect) then
            label.fill.effect.intensity = 0.0;
        end
        self[transName] = nil;
    end
    
end

function Instructions:onOk()
    --print("Instructions:onOk()")
    Runtime:dispatchEvent({name="soundrequest", type="button"}); -- play button sound
    self:contract();
end

function Instructions:onBackTap()
    if(self.expandedState == "contracted") then
        self:expand();
    end
end

function Instructions:nextInstruction()
    
    self.currentIndex = self.currentIndex +1;
    
    -- log event to analytics
    self.context:analyticslogEvent("Instructions-nextInstruction", {intructionIndex =self.currentIndex});
    
    --print("nextInstruction()" .. self.currentIndex);
    
    if(self.currentIndex > #self.instructions) then
        -- log event to analytics
        self.context:analyticslogEvent("Instructions-NoMoreInstruction", {intructionIndex =self.currentIndex});
        return;
    end
    
    local instruction = self.instructions[self.currentIndex];
    self.currentInstruction = instruction;
    
    if(instruction.startDelay) then
        self:startDelay(instruction);
    elseif(instruction.startEvent) then
        self:waitForStartEvent(instruction);
    else
        self:showInstruction(instruction);
    end
end

function Instructions:showInstruction(instruction)
    --print("Instructions:showInstruction(instruction)");
    
    --local s = 
    self.expandedLabel.text = self.textSource:getText(instruction.textKey);
    
    
    self:showUI();
    self:forceExpand();
    
    if(instruction.tipKey) then
        self.label.text = self.textSource:getText(instruction.tipKey);
        self.highlightContracted = true;
    else
        self.label.text = "...";
        self.highlightContracted = false;
    end
    
    
    if(instruction.highlightUI) then
        self.uiMetaInfo:startHighlightUI(instruction.highlightUI, instruction.highlightUIParams);
        self.highlightedUI = instruction.highlightUI;
    end
    
    
    if(instruction.duration) then
        self:duration(instruction);
    elseif(instruction.endEvent) then
        self:waitForEndEvent(instruction);
    else
        self.nextAfterContraction = true;
        --print("Instructions Warning: instruction at index" .. tostring(self.currentIndex) .. " does not have either duration or end even defined");
    end
end

function Instructions:pause()
    if(self.timer) then
        timer.pause(self.timer);
    end    
end

function Instructions:resume()
    if(self.timer) then
        timer.resume(self.timer);
    end    
end


function Instructions:removeCurrent()
    
    if(self.timer) then
        timer.cancel(self.timer);
        self.timer = nil;
    end
    
    if(self.endEventName)then
        Runtime:removeEventListener(self.endEventName, self.endEventListener);
        self.endEventName = nil;
    end
    
    if(self.startEventName)then
        Runtime:removeEventListener(self.startEventName, self.startEventListener);
        self.startEventName = nil;
    end
    
    
    --print("self.highlightedUI: " .. tostring(self.highlightedUI))
    
    if(self.highlightedUI) then
        self.uiMetaInfo:stopHighlightUI(self.highlightedUI);
        self.highlightedUI = nil;
    end
    
    --[[
    if(self.currentArrow) then
        self.currentArrow.g:removeSelf();
        self.currentArrow = nil;
    end
    ]]
    
    --[[
    if(self.expandedState == "expanded") then
        
    else
        self:hideUI();
    end
    ]]
    
    self:hideUI();
    
    --self.label.text = nil;
    --self.back.isVisible = false;
end




function Instructions:startDelay(instruction)
    self.timer = timer.performWithDelay(instruction.startDelay, function() self.timer = nil; self:showInstruction(instruction); end);
end

function Instructions:duration(instruction)
    self.timer = timer.performWithDelay(instruction.duration, 
    function()
        self.timer = nil; 
        
        if(self.expandedState == "expanded") then
            self.nextAfterContraction = true;
        else
            self:removeCurrent();
            self:nextInstruction(); 
        end
    end
    );
end

function Instructions:waitForStartEvent(instruction)
    local name = instruction.startEvent;
    self.startEventName = name;
    Runtime:addEventListener(name, self.startEventListener)
end

function Instructions:waitForEndEvent(instruction)
    local name = instruction.endEvent;
    self.endEventName = name;
    Runtime:addEventListener(name, self.endEventListener)
end


function Instructions:validateEvent(event, startParams)
    local params;
    if(startParams)then
        params = self.currentInstruction.startEventParams;
    else
        params = self.currentInstruction.endEventParams;
    end
    
    -- if any params
    if(params) then
        -- see if params values match
        for i=1, #params do
            local par = params[i];
            
            -- has key and subkey
            if(par.subkey and par.key) then
                
                
                if(not event[par.key]) then
                    --print("event does not have key: " .. par.key)
                    return false; -- event does not have this key 
                end
                
                --print("key: " .. par.key .. ", subkey: " .. par.subkey .. ", desited value:".. par.val .. ", event[par.key][par.subkey]: " .. event[par.key][par.subkey]);
                
                if(event[par.key][par.subkey] ~= par.val) then
                    return false;
                end
                
                -- has only a key
            elseif(event[par.key] ~= par.val) then -- not a match
                return false; -- this is not an event we are wating for
            end
        end
    end
    
    return true;
end


function Instructions:onStartEvent(event)
    
    if(self:validateEvent(event, true)) then -- is this the event ?
        --Runtime:removeEventListener(self.endEventName, self.eventListener);
        --self.endEventName = nil;
        self:removeCurrent();
        self:showInstruction(self.currentInstruction);
    end
end

function Instructions:onEndEvent(event)
    
    if(self:validateEvent(event, false)) then -- is this the event ?
        --Runtime:removeEventListener(self.endEventName, self.eventListener);
        --self.endEventName = nil;
        self:removeCurrent();
        self:nextInstruction();
    end
end

function Instructions:start()
    self:nextInstruction();
end

function Instructions:restart()
    self:removeCurrent();
    self.currentIndex = 0;
    
    self.expandedState = "hidden";
    self.back.height = self.backH;
    
    
    
    transition.cancel(self.back)
    transition.cancel(self.eventBlocker)
    transition.cancel(self.okButton)
    transition.cancel(self.expandedLabel)
    transition.cancel(self.label)
    
    self.back.alpha = 1;
    self.eventBlocker.alpha = 1;
    self.okButton.alpha = 1;
    self.expandedLabel.alpha = 1;
    self.label.alpha = 1;
    
    
    self.back.isVisible = false;
    self.eventBlocker.isVisible = false;
    self.okButton.isVisible = false;
    self.expandedLabel.isVisible=false;
    self.label.isVisible= false;
    
end

--[[
function Instructions:addArrow(arrowTarget)
    
    local w,h,top, left = self.uiMetaInfo:getUIPosition(arrowTarget);
    --print(names[i] .. ": w = " .. tostring(w) .. ", h = " .. tostring(h) .. ", top = " .. tostring(top) .. ", left = " .. tostring(left));        
    if(w and h and top and left) then
        
        local g  = display.newGroup();
        self.g:insert(g);
        
        local bounds = self.bounds;
                 
        
        local line = display.newLine(g, bounds.minX, self.lineStartY, bounds.centerX, self.lineStartY, left, top);
        line.strokeWidth = self.arrowStrokeWidth;
        line.alpha = 0.5;
        
        line = display.newLine(g, left+w, top, left, top,left, top+h);
        line.strokeWidth = 2;
        
        self.currentArrow = {g=g, };
        
    else
        print("Instructions addArrow : Unable to get dimensions of Arrow target: " .. tostring(arrowTarget));
    end
    
end
]]

function Instructions:destroy()
    self:removeCurrent();
    
    if(self.g) then
        self.expandedState = "destroyed";
        transition.cancel(self.back);
        transition.cancel(self.expandedLabel);
        transition.cancel(self.label);
        transition.cancel(self.eventBlocker);
        transition.cancel(self.okButton);
        self.g:removeSelf();
        self.g = nil;
    end
end

return Instructions;


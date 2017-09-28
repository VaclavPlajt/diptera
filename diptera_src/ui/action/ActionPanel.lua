
local ActionPanel =  {}

-- params: panelDef, context, group, height, margin, imgDir, top, left
function ActionPanel:new(params)
    
    local newPanel = {}; -- create new object
    
    -- set meta tables so lookups will work
    setmetatable(newPanel, self)
    self.__index = self
    
    newPanel:initPanel(params);
    
    return newPanel;
end


function ActionPanel:initPanel(params)
    
    -- panel group
    local g = display.newGroup();
    params.group:insert(g);
    self.group = g;
    local bounds = params.context.displayBounds;
    self.slideMaxX = bounds.maxX;
    self.left = params.left;
    self.slideMinX = bounds.minX - (self.slideMaxX-params.left); --self.left - (self.slideMaxX-params.left);
    
    local defaultIcon = "default";
    local defaultBtnLabelColor = params.context.uiConst.defaultBtnLabelColor;
    --local context = params.context;
    local margin  = params.margin;
    local uiConst =  params.context.uiConst;
    local fontSize = uiConst.defaultBtnFontSize;
    local fontName = uiConst.fontName;
    local panelDef = params.panelDef;
    local panelActionsDefs = panelDef.actions;
    --local btnH = params.height - 3*margin - fontSize;
    local btnH = params.height - 2*margin;
    local btnW = 3.4*btnH;
    --print("Action panel buttons h:" .. btnH .. ", w:" .. btnW)
    local cx = params.left + margin + 0.5*btnW+0.5*uiConst.defBtnStrokeWidth;
    local dx = margin + btnW + uiConst.defBtnStrokeWidth;
    local cy = params.top + 0.5*params.height;
    local btnCy = params.top + margin + 0.5*btnH;
    --local labelCy = params.top + 2*margin + btnH + 0.5*fontSize;
    --local labelCy = params.top + 2*margin + 0.5*btnH;-- + 0.5*fontSize;
    --local labelH = fontSize*1.2;
    local img = params.context.img;
    local textSource = params.context.textSource;
    
    self.panelActionsDefs = panelActionsDefs;
    self.selectedItem = nil;
    
    local infoPanel = params.infoPanel;
    self.infoPanel = infoPanel;
    
    
    if(infoPanel) then
        cx = cx + infoPanel.width + margin;
        self:insertInfoPanel(infoPanel);
    end
    
    local actionObjects = {};
    self.actionObjects = actionObjects;
    
    for i=1, #panelActionsDefs do
        local actionDef = panelActionsDefs[i];
        
        
        if(actionDef.twoState) then -- create two state button
            
            local firstText = textSource:getText(actionDef.firstDescKey);
            local secondText = textSource:getText(actionDef.secondDescKey); 
            
            local params = {layer=g,context=params.context,imgDir =params.imgDir,cx =cx, btnY=btnCy, btnW=btnW, btnH=btnH,
                --labelY=labelCy, labelW=btnW+margin, labelH=labelH, fontName=fontName,
                fontSize=fontSize,
                firstText=firstText, secondText=secondText, --firstIcon=actionDef.firstIcon, secondIcon=actionDef.secondIcon,
                firstIcon=defaultIcon, secondIcon=defaultIcon,
                onFirstAction = function(event) params.onActionSelected(event, actionDef, true) end,
                onSecondAction = function(event) params.onActionSelected(event, actionDef, false) end,
                w=dx,h=params.height, cy=cy, labelColor = defaultBtnLabelColor
            };
            
            local twoStateBtn = require("ui.comp.TwoStateButton"):new(params);
            twoStateBtn:setFirstState();
            actionObjects[i] = {btn=twoStateBtn, enabled= true};
            cx = cx +dx;
        elseif(actionDef.countChooser) then -- create count chooser
            
            local countChooser = require("ui.comp.CountChooser"):new{
                layer=g,context=params.context,left=params.left, top=params.top,
                h=params.height , fontName=fontName, 
            onCountChoosen = function(event, num) params.onActionSelected(event, actionDef, num) end};
            
            actionObjects[i] = {btn=twoStateBtn, enabled= true};
            cx = cx + countChooser.w;
            
        else -- create button and disabling overlay
            
            local text = textSource:getText(actionDef.descKey);
            
            local btn =img:newBtn{dir=params.imgDir, name=defaultIcon, --actionDef.icon,
                group=g , cx=cx, cy = btnCy, fontSize=fontSize,
                onAction=function(event) params.onActionSelected(event, actionDef) end ,
            w= btnW, h= btnH, label=text, labelColor = defaultBtnLabelColor, hasOver = true};
            
            
            local overlayRect = display.newRect(g, cx, cy, dx, params.height);
            overlayRect:setFillColor(0.5, 0.4);
            overlayRect.isVisible = false;
            
            actionObjects[i] = {btn=btn, overlayRect = overlayRect, enabled = true};
            cx = cx +dx;
        end
        
        
    end    
end

function ActionPanel: destroy()
    --print("ActionPanel: destroy()");
    
    
    if(self.group) then
        transition.cancel(self.group)
        self.group:removeSelf();
        self.group = nil;
    end
end

function ActionPanel:slideIn()
    --print("ActionPanel:slideIn()")
    self.group.isVisible = true;
    
    transition.cancel(self.group);
    self.group.x = 0;
    transition.from(self.group, {x=self.slideMaxX, time=250})
end

function ActionPanel:slideOut()
    --print("ActionPanel:slideOut()")
    transition.cancel(self.group);
    transition.to(self.group, {x=self.slideMinX, time=250, onComplete = 
        function()
            self.group.isVisible = false;
            self.group.x = 0;
            if(self.infoPanel) then
                self.infoPanel.isVisible = false;
            end
        end
    });
    
end

function ActionPanel:insertInfoPanel(infoPanel)
    self.group:insert(infoPanel.g);
end

function ActionPanel:updateSelection(newSelectedItem)
    
    self.selectedItem = newSelectedItem;
    
    if(self.infoPanel) then
        self.infoPanel:setInfoObject(newSelectedItem); 
    end
end

-- updates values and states of anction panel and embedded info panel
function ActionPanel:updateStates()
    
    local defs = self.panelActionsDefs;
    local selectedItem = self.selectedItem;
    
    
    
    if(defs and selectedItem and #defs > 0) then
        local actionsObjects = self.actionObjects;
        -- for each action disable/enable by property value
        for i=1,#defs do
            local def = defs[i];
            
            local disablingProperty =  def.disablingProperty;
            local enablingProperty = def.enablingProperty;
            
            
            -- disable action when property value == true, enable otherwise
            if(disablingProperty) then
                local actionObject = actionsObjects[i];
                local val = selectedItem[disablingProperty];
                
                if(val and actionObject.enabled) then -- disable
                    actionObject.btn:setEnabled(false);--.isHitTestable = false;
                    actionObject.overlayRect.isVisible = true;
                    actionObject.enabled = false;
                elseif(not val and actionObject.enabled==false) then -- enable
                    actionObject.btn:setEnabled(true);--.isHitTestable = true;
                    actionObject.overlayRect.isVisible = false;
                    actionObject.enabled= true;
                end
                
            end
            
            -- disable action when property value == false, enable otherwise
            if(enablingProperty) then
                local actionObject = actionsObjects[i];
                local val = selectedItem[enablingProperty];
                --print("updating enablingProperty: ".. enablingProperty .. ", val: " .. tostring(val));
                
                if(val and actionObject.enabled==false) then -- enable
                    if(def.twoState) then
                        actionObject.btn:setFirstState();
                        actionObject.enabled = true;
                    else
                        actionObject.btn:setEnabled(true);--.isHitTestable = true;
                        actionObject.overlayRect.isVisible = false;
                        actionObject.enabled = true;
                    end
                elseif(not val and actionObject.enabled==true) then -- disable
                    if(def.twoState) then
                        actionObject.btn:setSecondState();
                        actionObject.enabled = false;
                    else
                        actionObject.btn:setEnabled(false);--.isHitTestable = false;
                        actionObject.overlayRect.isVisible = true;
                        actionObject.enabled= false;
                    end
                end
                
            end
            
        end
    end
    
    
    if(self.infoPanel) then
        self.infoPanel:updateValues(); 
    end
end


return ActionPanel;


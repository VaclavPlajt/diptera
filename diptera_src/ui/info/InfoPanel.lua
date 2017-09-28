
local InfoPanel =  {}

local propertiesKeyPrefix = "property.";

function InfoPanel:new(layer, height,top, left, context, infoObject)
    local newInfoPanel = {};
    
    -- set meta tables so lookups will work
    setmetatable(newInfoPanel, self);
    self.__index = self;
    
    --newInfoPanel.g = layer;
    newInfoPanel.height = height;
    newInfoPanel.context = context;
    newInfoPanel.infoObject = infoObject; -- the objects informations are about
    newInfoPanel.bindings = {};
    newInfoPanel.lastBindingsVals = {};
    newInfoPanel.left = left;
    newInfoPanel.top = top;
    
    newInfoPanel:createUI(layer, height,top, left, context, infoObject)
    return newInfoPanel;
    
end


function InfoPanel:createUI(layer, height,top, left, context, infoObject)
    
    local uiConst = context.uiConst;
    local unitHeight = height * 0.25;
    
    -- bindings
    local bindings = infoObject.infoProperties;
    if(bindings and #bindings <= 0) then bindings = nil; end;
    
    -- progress property
    local progrProp = infoObject.progressProperty;
    
    -- icon size
    local iconSize;
    if(progrProp) then
        iconSize = unitHeight * 3;
    else
        iconSize = height;--unitHeight * 3;
    end
    
    self.iconSize = iconSize;
    
    
    local g = display.newGroup();
    layer:insert(g);
    self.g = g;
           
    
    local width;
    if(bindings)then
        self.bindings = bindings;
        width = iconSize + uiConst.infoPanelBindingsWidth;
    else
        width = iconSize; 
    end
    
    self.width = width;
    
    -- add background
    local back = display.newRoundedRect(g, left + 0.5*width, top + 0.5*height, width, height, 5);
    --back:setFillColor(0.3);
    back:setFillColor(unpack(uiConst.defBtnFillColor.default))
    
    --back.stroke = {type="image", filename= "img/comm/win_stroke.png"};
    --back.strokeWidth = 2;
    back.blendMode = "add";
    
    -- add icon
    local iconImgName = infoObject.icon;
    local iconDir = infoObject.iconDir;
    if(iconImgName and iconDir) then
        
        local iconFullPath = iconDir .. iconImgName;
        --print("Icon path:" .. iconFullPath)
        self.lastIconName = iconFullPath;
        local icon = display.newImageRect(g,iconFullPath,iconSize, iconSize);
        icon.x = left+0.5*iconSize;
        icon.y = top+0.5*iconSize;
        self.icon = icon;
    else
        print("Warning: InfoBar without icon! ");
    end
    
    -- add progress bar
    
    if(progrProp) then
        
        local maxVal;
        if(type(progrProp.max)=="string")then
            maxVal = infoObject[progrProp.max];
        else
            maxVal = progrProp.max;
        end
        
        local val = infoObject[progrProp.name];
        local progressIndicator = require("ui.comp.ProgressBar"):new(g, top+unitHeight*3, left, unitHeight, width, true, maxVal, context);
        progressIndicator:setValue(val);
        self.progressIndicator = progressIndicator;
    end
    
    -- add bindings
    if(bindings) then
        self.bindings = bindings;
        local bLeft = left + iconSize;
        local bWidth = uiConst.infoPanelBindingsWidth;
        self:addBindings(bindings,g, top, bLeft,unitHeight,bWidth, context);
    end
    
end

function InfoPanel:destroy()
    if(self.g) then
        self.g:removeSelf();
        self.g = nil;
    end
end

function InfoPanel:addBindings(bindings,g, top, left,unitHeight,width, context)
    local textSource = context.textSource;
    local uiConst = self.context.uiConst;
    local fontSize = uiConst.smallFontSize;
    local margin =  uiConst.defaultMargin;
    local propertyValueLabels = {};
    local keyWidth = width*0.75-margin;
    local keyCx = left + keyWidth*0.5;
    local valueWidth = width*0.25-margin;--) - keyWidth;
    local valueCx = left + keyWidth + margin+ valueWidth*0.5;
    
    
    local cy = top + unitHeight*0.5+margin;
    
    for i=1, #bindings do
        local propertyName = bindings[i]; -- name of bounded property 
        
        -- add property name text
        local propS = textSource:getText(propertiesKeyPrefix .. propertyName) .. ":";
        local label = display.newText{parent = g,text=propS,
            x=keyCx, y=cy, 
            width=keyWidth, 
            --height=unitHeight,
            align = "left",
            font=uiConst.fontName,fontSize=fontSize
        };
        
        
        -- add property value text
        local val = self.infoObject[propertyName];
        self.lastBindingsVals[propertyName] = val;
        local valueLabel = display.newText{parent = g,text=tostring(val),
            x=valueCx, y=cy, 
            width=valueWidth, 
            --height=unitHeight,
            align = "left",
            font=uiConst.fontName,fontSize=fontSize
        };
        
        --display.newCircle(layer, valueCx, cy, 5);
        
        propertyValueLabels[propertyName] = valueLabel;
        
        cy = cy + unitHeight;
    end
    
    self.propertyValueLabels = propertyValueLabels;
end

--[[
function InfoPanel:moveToActionPanel(actionPanel)
    local newSuperGroup = actionPanel.group;
    -- insert this infopane;s group to given group
    newSuperGroup:insert(self.g);
    
end
]]

function InfoPanel:updateValues()
    
    local infoObject = self. infoObject;
    
    
    
    
    -- update finess indicator
    local progrProp = infoObject.progressProperty;
    
    if(progrProp) then
        --local maxVal = infoObject[progrProp.max];
        local val = infoObject[progrProp.name];
        self.progressIndicator:setValue(val);
    end
    
    -- updated bindings
    local bindings = self.bindings;
    local labels = self.propertyValueLabels;
    
    for i=1, #bindings do
        local propertyName = bindings[i]; -- name of bounded property 
        local val = self.infoObject[propertyName]; 
        if(self.lastBindingsVals[propertyName] ~= val) then
        self.lastBindingsVals[propertyName] = val;
        labels[propertyName].text = tostring(val);
        end
    end
end


function InfoPanel:setInfoObject(newInfoObject) 
    self.infoObject = newInfoObject;
    self.lastBindingsVals = {};
    
    -- update finess max value indicator
    
    local progrProp = newInfoObject.progressProperty;
    
    if(progrProp) then
        local maxVal;
        if(type(progrProp.max)=="string")then
            maxVal = newInfoObject[progrProp.max];
        else
            maxVal = progrProp.max;
        end
        --local val = infoObject[progrProp.name];
        self.progressIndicator:setMaxValue(maxVal, progrProp.formating);
    end
    
    -- update icon if needed
    local iconImgName = newInfoObject.icon;
    local iconDir = newInfoObject.iconDir;
    if(iconImgName and iconDir ) then
        
        local iconFullPath = iconDir .. iconImgName;
        
        if(iconFullPath ~= self.lastIconName) then
            self.lastIconName = iconFullPath;
            if(self.icon) then self.icon:removeSelf() end;
            
            local iconSize= self.iconSize;
            local icon = display.newImageRect(self.g,iconFullPath,iconSize, iconSize);
            icon.x = self.left+0.5*iconSize;
            icon.y = self.top+0.5*iconSize;
            self.icon = icon;
        end
    else
        print("Warning: InfoBar without icon! ");
    end
    
    self:updateValues();
end


return InfoPanel;


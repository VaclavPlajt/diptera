

local UIMetaInfo = {}



function UIMetaInfo:new(actionMenu, minionAssigner, quickActionsMenu, materialCounter)
    
    local newUIMetaInfo = {};
    
    -- set meta tables so lookups will work
    setmetatable(newUIMetaInfo, self)
    self.__index = self
    
    newUIMetaInfo.uiComponents = { 
        actionMenu=actionMenu, minionAssigner=minionAssigner,
        quickActionsMenu=quickActionsMenu, materialCounter=materialCounter,
    };
    newUIMetaInfo.highlightedUI = {};
    
    return newUIMetaInfo;
    
end

function UIMetaInfo:setInstructions(instructions)
    self.uiComponents.instructions =instructions;
end

local function getDimensions(o) 
    local w,h,top,left;
    
    if(o.w) then
        w = o.w;
    elseif(o.width) then
        w = o.width;
    else
        print("UIMetaInfo: getDimensions object does not have recognizable 'width' property");
        return;
    end
    
    if(o.h) then
        h = o.h;
    elseif(o.height) then
        h = o.height;
    else
        print("UIMetaInfo: getDimensions object does not have recognizable 'height' property");
        return;
    end
    
    if(o.top) then
        top = o.top;
    elseif(o.minY) then
        top = o.minY;
    elseif(o.cy) then
        top = o.cy-h*0.5;
    else
        print("UIMetaInfo: getDimensions object does not have recognizable 'top' or 'cy' property");
        return;
    end
    
    if(o.left) then
        left = o.left;
    elseif(o.minX) then
        left = o.minX;
    elseif(o.cx) then
        left = o.cx-w*0.5;
    else
        print("UIMetaInfo: getDimensions object does not have recognizable 'left' or 'cx' property");
        return;
    end
    
    return w,h,top,left;
end

-- returns width, height, top, left coordonates of component or nil when given name is not supported
function UIMetaInfo:getUIPosition(name)
    
    local ui = self.uiComponents[name];
    
    if(ui)then
        return getDimensions(ui);
    else
        print("UIMetaInfo Warning: unreognized compoent name : " .. tostring(name));
    end
    
    return;
end


function UIMetaInfo:startHighlightUI(uiName, params)
    
    local ui = self.uiComponents[uiName];
    
    if(ui== nil) then
        print("UIMetaInfo: Unrecognized UI to highlight: " .. tostring(uiName));
        return;
    end
    
    if(ui.startHighlight) then
        ui:startHighlight(params);
        self.highlightedUI[ui] = ui;
    else
        print("UIMetaInfo: UI component " .. tostring(uiName) .. " does not support highlight.");
    end
    
    -- self:startHighlight();
    
    --timer.performWithDelay(10000, function() self:stopHighlight() end);
    
    
end

function UIMetaInfo:stopHighlightUI(uiName)
    
    local ui = self.uiComponents[uiName];
    
    if(ui== nil) then
        print("UIMetaInfo: Unrecognized UI to stop highlight: " .. tostring(uiName));
        return;
    end
    
    if(ui.stopHighlight) then
        ui:stopHighlight();
        self.highlightedUI[ui] = nil;
    else
        print("UIMetaInfo: UI component " .. tostring(uiName) .. " does not support highlight stop.");
    end
    
end


function UIMetaInfo:isInstructionsVisible()
    
    local instr = self.uiComponents["instructions"];
    if(instr == nil)then
        return false;
    end
    
    if(instr.expandedState == "hidden" or instr.expandedState == "destroyed") then
        return false;
    end
    
    return true;
end


function UIMetaInfo:destroy()
    
    for k,ui in pairs(self.highlightedUI) do
        if(ui and ui.stopHighlight) then
            ui:stopHighlight();
        end
    end
    
    self.uiComponents = nil;
    
end




return UIMetaInfo;


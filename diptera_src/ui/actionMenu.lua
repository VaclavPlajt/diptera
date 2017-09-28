-- main actions menu
local actionMenu ={}


function actionMenu:init(context, layer)
    
    self.context = context;
    self.textSource = context.textSource;
    self.img = context.img;
    self.layer = layer;
    self.uiConst = context.uiConst;
    
    
    local bounds = context.displayBounds;
    self.height = self.uiConst.aMHeight;
    self.margin = self.uiConst.defaultMargin; -- content pixels
    self.decsLineHeight = self.uiConst.bigFontSize*1.2 + self.margin;--27;
    self.divsionLineWidth = 1;
    
    -- back button functinality
    self.backStackSize = 0;
    self.backStack = {};
    --self.btnH = self.height - 2*self.margin - self.decsLineHeight - self.divsionLineWidth;
    --self.btnW = self.btnH*0.5;
    
    self.minX = bounds.minX;
    self.maxX = bounds.maxX;
    self.minY = bounds.maxY - self.height;
    self.maxY = bounds.maxY;
    
    
    self.width = self.maxX - self.minX;
    self.centerX = self.minX + 0.5*self.width;
    self.centerY = self.minY + 0.5*self.height;
    
    -- load action definitions from json file
    local jsonIO = require("io.jsonIO");
    self.actionDefs = jsonIO:getTableFormFile("ui/actions.json");
    
    self.actionPanels = {}; -- table where created action panels are stored
    self.itemInfoPanels = {}; -- table for storing info panels
    self.titleTexts = {}; -- texts to show in menu title
    self.actionPanelHeight = self.height - self.decsLineHeight;
    
    actionMenu:createContainer();
    
    -- content update timer
    self.updateTimer = timer.performWithDelay( self.uiConst.aPanelsUpdatePeriod, function() self:updateCurrentPanel(nil) end , -1 );
    
    -- listen for new available actions
    self.actionsAvailableListener = function(event) self:actionsAvailable(event); end;
    Runtime:addEventListener("actionsAvailable", self.actionsAvailableListener);
    
    
    
    return self;
end

function actionMenu:destroy()
    
        
    if(self.actionsAvailableListener) then
        Runtime:removeEventListener("actionsAvailable", self.actionsAvailableListener);
        self.actionsAvailableListener = nil;
    end
    
    if(self.containerGroup) then
        self.containerGroup:removeSelf();
        self.containerGroup = nil;
    end
    
    if(self.actionPanels) then -- destroy all action panels
        for key, actionPanel in pairs(self.actionPanels) do
            actionPanel:destroy();
        end
        
        self.actionPanels= nil;
    end
    
    if(self.itemInfoPanels) then
        
        for key, infoPanel in pairs(self.itemInfoPanels) do
            infoPanel:destroy();
        end
        
        self.itemInfoPanels= nil;
    end
    
    self.currentActionPanelName = nil;
    
end


function actionMenu:createContainer()
    local g = display.newGroup();
    self.layer:insert(g);
    self.containerGroup = g;
    
    -- container background
    local uiUtils = require("ui.uiUtils");
    local back  = uiUtils.newUiBackRect(g, self.minX+self.width*0.5, self.minY+self.height*0.5, self.width, self.height, self.context);
    self.back = back;
    
    
    local descCy = self.minY+0.5*self.decsLineHeight -self.divsionLineWidth;
    -- desc text back
    local descBack  =  display.newRect(g, self.minX+self.width*0.5, descCy, self.width, self.decsLineHeight);
    --descBack:setFillColor(0, 0.3);
    descBack.fill = {
        type = "gradient",
        color1 = { 0,0,0,0.4 },
        color2 = { 0,0,0,0.0 },
        direction = "right"
    }
    
    -- container description line text
    local descText =  display.newText{
        parent = g,
        text= self.textSource:getText("actions.nothingSelected"),
        x=self.centerX,
        y=descCy,--self.minY+0.5*self.decsLineHeight -self.divsionLineWidth,
        --width=self.width-2*self.margin,
        --height=self.decsLineHeight - self.divsionLineWidth,
        align = "left",
        font=self.uiConst.fontName,fontSize=self.uiConst.bigFontSize
    };
    
    descText.anchorX = 0;
    descText.x = self.minX + self.margin;
    descText:setFillColor(unpack(self.uiConst.defaultFontColor))
    self.descText = descText;
    
    
    local suffixText =  display.newText{
        parent = g,
        text= "",
        x=self.centerX,
        y=self.minY+0.5*self.decsLineHeight -self.divsionLineWidth+2,
        --width=self.width-2*self.margin,
        --height=self.decsLineHeight - self.divsionLineWidth,
        align = "left",
        font=self.uiConst.fontName,fontSize=self.uiConst.bigFontSize
    };
    
    suffixText.anchorX = 0;
    suffixText.x = self.minX + self.margin;
    --suffixText:setFillColor(unpack(self.uiConst.defaultFontColor))
    suffixText:setFillColor(unpack(self.uiConst.highlightedFontColor))
    suffixText.isVisible = false;
    self.suffixText = suffixText;
    suffixText.blendMode  = "add";
    
    
    -- division line
    local y = self.minY + self.decsLineHeight - self.divsionLineWidth; 
    local divLine = display.newLine(g, self.minX, y, self.maxX, y);
    divLine.strokeWidth = self.divsionLineWidth;
    divLine:setStrokeColor( 0.5, 0.2, 0.2, 1 );
    --divLine:setStrokeColor( 0.4, 0.1, 0.1, 0.5 );
    divLine.blendMode = "add";
    
    
    self.actionPanelLeft = self.minX;
    
end

--[[
function actionMenu:onBackBtnAction(event)
    --print("onBackBtnAction(event)")
    
    
    -- retrieve action panel from history
    if(self.backStackSize > 0) then
        local oldActionsName = self.backStack[self.backStackSize];
        self.backStackSize = self.backStackSize -  1;
        
        local actionsDef = self.actionDefs[oldActionsName];
        self:setActionPanel(oldActionsName,actionsDef, event);
    end
    
    
    if(self.backStackSize <= 0) then
        self.backBtn:setEnabled(false);
        --self.backBtn.alpha = 0.5;
        self.backBtn.isVisible = false;
    end
    
end
]]
--[[
function actionMenu:saveCurrentToHistory()
    self.backStackSize = self.backStackSize + 1;
    self.backStack[self.backStackSize] = self.currentActionPanelName;
    self.backBtn:setEnabled(true);
    self.backBtn.isVisible = true;
    --self.backBtn.alpha = 1;
end
]]



function actionMenu:actionsAvailable(event)
    
    local actionsName = event.actions;
    
    -- no actions to show, clear action menu
    if(actionsName == nil or actionsName == "") then
        self:clearActions();
        return;
    end
    
    -- no need to change panel, only update parameters
    if(actionsName == self.currentActionPanelName) then 
        self:updateCurrentPanel(event);
        return;
    end
    
    -- map item selected, choose actions according to item type
    if(actionsName == "itemSelected") then
        self:itemSelectedActions(event)
        return;
    end
    
    
    -- general actions
    self:setActionPanel(event,actionsName, nil);
    
end

function actionMenu:updateCurrentPanel(event)
    
    if(self.currentActionPanel == nil) then return; end;
    
    if(event) then-- parameters and selection need update
        self.currentActionParams = event.params;
        local item = event.params.item;
        if(item) then
            self.currentActionPanel:updateSelection(item);
        end
    else
        if(self.currentActionPanel.infoPanel) then
            local item = self.currentActionPanel.infoPanel.infoObject;
            
            if(item.destroyed or item.removed)then
                self:clearActions();
                return;
            end
        end
        --self.currentActionPanel:updateStates();
    end
    
    self.currentActionPanel:updateStates();
end

function actionMenu:itemSelectedActions(event)
    --print("item selection actions")
    local actionsName = event.actions;
    local owned = event.params.owned;
    local selectedItem = event.params.item;
    local itemType = selectedItem.typeName;
    
    if(owned) then
        actionsName = itemType .. "_actions";
    else
        if(itemType == "DestroyedKeep") then
            actionsName = "DestroyedKeep_actions";
        else
            actionsName = "enemy_" .. itemType .. "_actions";
        end
    end
    
    --print("actionName: " .. actionsName .. "self.currentActionPanelName: " .. tostring(self.currentActionPanelName))
    
    -- no need to change panel, update parameters only
    if(actionsName == self.currentActionPanelName) then 
        --print("selection of same item type");
        self:updateCurrentPanel(event);
        return;
    end
    
    self:setActionPanel(event,actionsName, selectedItem);
end



function actionMenu:clearActions()
    if(self.currentActionPanel) then
        self.descText.text = self.textSource:getText("actions.nothingSelected");
        self.suffixText.isVisible = false;
        self.currentActionPanel:slideOut(); 
        self.currentActionPanel = nil;
        self.currentActionPanelName = nil;
        self.currentActionParams = nil;
    end
end


function actionMenu:setActionPanel(event,actionsName, selectedItem)
    
    --print("set action: " .. actionsName);
    ---TODO rozdelit na metody
    local actionsDef = self.actionDefs[actionsName];
    if(not actionsDef ) then
        print("Unknown actions! :" .. actionsName);
        self:clearActions();
        return;
    end
    
    --[[
    if(event.keepHistory) then
        self:saveCurrentToHistory();
    end
    ]]
    
    local infoPanel;
    local panelsH =  self.actionPanelHeight-self.margin;
    
    if(selectedItem) then
        local typeName = selectedItem.typeName;
        infoPanel = self.itemInfoPanels[typeName];
        
        
        if(infoPanel== nil) then
            
            infoPanel = require("ui.info.InfoPanel"):new(
            self.containerGroup,panelsH,self.minY + self.decsLineHeight+self.margin,  self.actionPanelLeft+self.margin,
            self.context, selectedItem);
            
            self.itemInfoPanels[typeName] = infoPanel;
        end
        
    end
    
    local actionPanel = self.actionPanels[actionsName];
    if(actionPanel == nil) then
        -- create action panel
        actionPanel = require("ui.action.ActionPanel"):new{
            panelDef=actionsDef, context=self.context, group= self.containerGroup,
            height=panelsH,--self.actionPanelHeight,
            margin=self.margin,
            imgDir=self.actionDefs.iconsDirectory,
            top = self.minY + self.decsLineHeight,
            left = self.actionPanelLeft,
            selectedItem = event.params.item,
            context = self.context,
            infoPanel = infoPanel,
            onActionSelected = function(event, actionDef, firstState) self:onActionSelected(event, actionDef, firstState) end
        }
        
        self.actionPanels[actionsName] = actionPanel;
        -- keep back button on top
        --self.backBtn:toFront()
    end
    
    if(infoPanel) then
        actionPanel:insertInfoPanel(infoPanel)
    end
    
    if(self.currentActionPanel) then
        self.currentActionPanel:slideOut(); 
    end
    
    if(event.params.item) then
        actionPanel:updateSelection(event.params.item);
    end
    
    actionPanel:slideIn();
    
    -- description
    local s = self.titleTexts[actionsName];
    
    if(s == nil) then
        s =  self.textSource:getText(actionsDef.titleKey);
        self.titleTexts[actionsName] = s;
    end
    
    self.descText.text = s;
    
    if(actionsDef.suffixKey) then
        --print("Action menu descText width:" .. self.descText.width);
        self.suffixText.x = self.descText.x + self.descText.width + self.margin;
        self.suffixText.isVisible = true;
        self.suffixText.text = self.textSource:getText(actionsDef.suffixKey);
    else
        self.suffixText.isVisible = false;
    end
    
    self.currentActionPanel = actionPanel;
    self.currentActionPanelName = actionsName;
    self.currentActionParams = event.params;
end

function actionMenu:onActionSelected(event, actionDef, genericParam)
    
    --[[
    if(actionDef.topLevelAction) then 
        Runtime:dispatchEvent{name="actionsAvailable", actions=actionDef.name, keepHistory=true};
    else
    ]]
    local actionName;
    
    if(actionDef.twoState) then
        if(genericParam) then
            actionName = actionDef.firstName;
        else
            actionName = actionDef.secondName;
        end
    else
        
        if(actionDef.countChooser) then
            self.currentActionParams.count = genericParam;
        end
        
        actionName = actionDef.name;
    end
    
    Runtime:dispatchEvent({name="soundrequest", type="button"}); -- play button sound
    Runtime:dispatchEvent{name="actionSelected", action=actionName, params = self.currentActionParams};
    --end
    
end


--[[
function actionMenu:removeSelf()
    if(self.actionsAvailableListener) then
        Runtime:removeEventListener("actionsAvailable", self.actionsAvailableListener);
        self.actionsAvailableListener = nil;
    end
end
]]

--[[
function actionMenu:setDescription(text)
    self.descText.text = text;
    
end
]]

return actionMenu;




local HelpLayerUI = {}


function HelpLayerUI:new(belowUILayer, uiLayer, context,uiMetaInfo,gameConst)
    
     local newHelpUI = {};
    
    -- set meta tables so lookups will work
    setmetatable(newHelpUI, self)
    self.__index = self;
    
    newHelpUI.context = context;
    newHelpUI.belowUILayer = belowUILayer;
    newHelpUI.uiLayer= uiLayer;
    newHelpUI.uiMetaInfo = uiMetaInfo;
    newHelpUI.visible = false;
    newHelpUI.gameConst= gameConst;
    
       
    return newHelpUI;
end

function HelpLayerUI:show()
    
    if(self.visible) then return; end;
    
    -- log event to analytics
    self.context:analyticslogEvent("HelpLayerUI-show");
    
    -- pause the game
    Runtime:dispatchEvent{name="actionSelected", action="pauseGame"};
    
    self.visible = true;
    --print("HelpLayerUI:show()");
    local context = self.context;
    --local img = context.img;
    local uiConst = context.uiConst;
    local bounds = context.displayBounds;
    local margin = uiConst.defaultMargin;
    local textSource = context.textSource;
    local instructionsMargin = 0; --TODO nastvit na 0, kdyz indtrukce nejdou videt ..
    if(self.uiMetaInfo:isInstructionsVisible()) then
        instructionsMargin = 50;
    end
    local minTop = bounds.minY + margin + instructionsMargin;
    
    -- show whole screen background below
    local back = display.newRect(self.belowUILayer, bounds.centerX, bounds.centerY, bounds.width, bounds.height);
    back:setFillColor(0.2,0.8);
    timer.performWithDelay(100, 
    function()
        if(self.back) then
            back:addEventListener("tap", function(event) self:hide(); return true; end);
            back:addEventListener("touch", function(event) return true; end);
        end
    end);
    
    self.back = back;
    
    local g = display.newGroup();
    self.uiLayer:insert(g);
    self.g = g;
    ---- show description for
    
    -- minion assigner
    local mw,mh, mtop,mleft = self.uiMetaInfo:getUIPosition("minionAssigner");
    local descWidth = mw;
    local descHeight = mh*0.75;
    --local minTop = bounds.minY + 100;
    --                  (w,top,left,g, title, text)
    self:addDescription(descWidth,mtop+0.5*mh-0.5*descHeight,mleft-descWidth,g, textSource:getText("help.assigner.title"), textSource:getText("help.assigner.text"));
    --local line = display.newLine(g, left+w, top, left, top,left, top+h);
    --line.strokeWidth = 2;
    
    
    -- quickmenu
    local w,h, top, left = self.uiMetaInfo:getUIPosition("quickActionsMenu");
    descWidth = w;
    descHeight = h;
    
    self:addDescription(descWidth,minTop,left-descWidth,g, textSource:getText("help.qmenu.title"), textSource:getText("help.qmenu.text"));
    --local line = display.newLine(g, left+w, top+h, left, top+h,left, top);
    --line.strokeWidth = 2;
    
    -- actions menu 
    -- dispatch no action avalable to clear the menu
    Runtime:dispatchEvent{name="actionsAvailable", actions=""};
    local aw,ah, atop, aleft = self.uiMetaInfo:getUIPosition("actionMenu");
    local counterWidth = 50+80+20;
    descWidth = aw--aw - mw - counterWidth;
    descHeight = ah*0.5;
    --                  (w,top,left,g, title, text)
    self:addDescription(descWidth,atop+ah-descHeight-margin,aleft+margin+counterWidth,g, textSource:getText("help.act_menu.title"), textSource:getText("help.act_menu.text"));
    --self:addDescription(descWidth,atop-descHeight,aleft+margin+counterWidth,g, textSource:getText("help.act_menu.title"), textSource:getText("help.act_menu.text"));
    --local line = display.newLine(g, left+w, top, left, top,left, top+h);
    --line.strokeWidth = 2;
    

    -- GAME GOAL !! 
    self:addDescription(bounds.width*0.5,minTop,bounds.minX+margin,g, textSource:getText("help.goal.title"), textSource:getText("help.goal.text"));
    
    self.buildingsList = require("ui.help.BuildingsList"):new(g, context,self.gameConst, bounds.minY+150, bounds.minX+margin);
    
end

function HelpLayerUI:addDescription(w,top,left,g, title, text)
    --print("adding desc :" .. title .. w .. ", h: ", h)
    local uiConst = self.context.uiConst;
    local margin = uiConst.defaultMargin;
    local titleTextSize = uiConst.bigFontSize;
    local titleH = titleTextSize + margin;
    local cx = left + 0.5*w;
    
    --title
    local titleLabel  = display.newText{
        text= title,
        parent = g,
        x = left,
        y = top+titleH*0.5,
        --width = w,
        font= uiConst.fontName,
        fontSize = uiConst.bigFontSize,
        align = "left"
    }
    titleLabel:setFillColor(unpack(uiConst.defaultFontColor))
    titleLabel.anchorX = 0;
    
    -- line
    local line;
    --if(lineEndX and lineEndY) then
    --    line = display.newLine(g, left, top+titleH, left+w, top+titleH, lineEndX, lineEndY);
    --else
        line = display.newLine(g, left, top+titleH, left+titleLabel.width, top+titleH);
    --end
    line.strokeWidth = 2;
    line:setStrokeColor(unpack(uiConst.clusterEdgeColor));
    line.blendMode = "add";
    
    --local textH = h - titleH;
    local textLabel  = display.newText{
        text= text,
        parent = g,
        x = cx,
        y = top+titleH,
        width = w,
        height = 0,
        font= uiConst.fontName,
        fontSize = uiConst.normalFontSize,
        align = "left"
    }
    textLabel:setFillColor(unpack(uiConst.defaultFontColor))
    textLabel.anchorY = 0;
end


function HelpLayerUI:hide()
    --print("HelpLayerUI:hide()");
    if(self.visible) then
        self.back:removeSelf();
        self.back= nil;
        self.g:removeSelf();
        self.g = nil;
        self.visible = false;
        
        -- resume game
        Runtime:dispatchEvent{name="actionSelected", action="resumeGame"};
    end
end



function HelpLayerUI:destroy()
    self:hide();
end








return HelpLayerUI;


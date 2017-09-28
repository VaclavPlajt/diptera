
local quickActionsMenu = {}

local showDebugBtns = false;

function quickActionsMenu:init(context, layer)
    self.context = context;
    
    local img = context.img;
    local uiConst = context.uiConst;
    local bigBtnSize = uiConst.qBigBtnSize;
    local smallBtnSize = uiConst.qSmallBtnSize;
    local margin = uiConst.defaultMargin;
    
    -- names positioned from left to right
    --local btnNames = {"help", "reset", "close"};
    local btnActions= {"help", "resetGame", "closeGame"};
    --local btnBig = {true, false, false};
    local btnText = {"?", "R", "X"}
    local imgDir = "ui/actions";
    
    if(showDebugBtns) then 
        btnActions[#btnActions+1] = "uiOff";
        btnText[#btnText+1] = "off";
        
        btnActions[#btnActions+1] = "zoomIn";
        btnText[#btnText+1] = "+";
        
        btnActions[#btnActions+1] = "zoomOut";
        btnText[#btnText+1] = "-";
    end
    
    
    
    
    local startRight = context.displayBounds.maxX-margin;
    local right = startRight;
    local top = context.displayBounds.minY + margin;
    
    -- menu group
    local g = display.newGroup();
    self.g = g;
    layer:insert(g);
    
    local btnSize = smallBtnSize;
    --for i,name in ipairs(btnNames) do
    for i= #btnActions, 1, -1 do
        
        local cx,cy;
        --local name = btnNames[i];
        --[[
        if(btnBig[i]) then -- big button
            btnSize = bigBtnSize;
        else -- small button
            btnSize = smallBtnSize;
        end
        ]]
        
        cx = right - 0.5*btnSize;
        cy = top + 0.5*btnSize;
        
        --print(name .. ": " .. btnSize);
        
        -- params: {dir= directory name, name=image name, group=display group, top=um, left= num, cx=num, cy = num,
        -- onAction=function(event), w= num, h=num, label=sting}
        -- either 'top' 'left' or 'cx' 'cy' has to be specified
        -- w,h - optional width and height parameters, button is scaled according to size of default image if not supplied
        local btn = img:newBtn{dir = imgDir, name="btn_back", group=g, cx=cx, cy=cy, w= btnSize, h= btnSize,
            label=btnText[i], hasOver = true, fontSize = uiConst.hugeFontSize,
            onAction = function() return self:onAction(btnActions[i]) end
        }
        
        --btn.blendMode = "add";
        
        right = right - btnSize - 2*margin;
    end
    
    self.left = right + margin;
    self.top = top;
    self.w = startRight - self.left;
    self.h = bigBtnSize + 2*margin;
    
    return self;
end

function quickActionsMenu:destroy()
    if(self.g) then
        self.g:removeSelf();
        self.g = nil;
    end
end

function quickActionsMenu:onAction(actionName)
    
    
    Runtime:dispatchEvent({name="soundrequest", type="button"}); -- play button sound
    
    if(actionName=="help") then
        -- pause the game
        Runtime:dispatchEvent{name="actionSelected", action="pauseGame"}
        self:onActionConfirmed(actionName);
    elseif(actionName=="resetGame") then
        -- pause the game
        Runtime:dispatchEvent{name="actionSelected", action="pauseGame"}
        ----- new(layer, width,height,textKey,onYes,onNo,onOk, context)
        require("ui.win.OptionPane"):new(self.g, nil,nil,"quicMenu.confirmRestart",function() self:onActionConfirmed(actionName) end, function()  self:resumeGame(); end,nil, self.context);
    elseif(actionName=="closeGame") then
        -- pause the game
        Runtime:dispatchEvent{name="actionSelected", action="pauseGame"}
        ----- new(layer, width,height,textKey,onYes,onNo,onOk, context)
        require("ui.win.OptionPane"):new(self.g, nil,nil,"quicMenu.confirmQuit",function() self:onActionConfirmed(actionName) end,function()  self:resumeGame(); end, nil, self.context);
    elseif(actionName=="uiOff" or actionName=="zoomIn" or actionName=="zoomOut") then
        self:onActionConfirmed(actionName);
    else
        print("Warning quickMenu: unknown action " .. actionName)
    end
    
    -- log event to analytics
    self.context:analyticslogEvent("quickActionsMenu-" .. actionName);
    
    return true;
end

function quickActionsMenu:resumeGame()
    -- resume game
    Runtime:dispatchEvent{name="actionSelected", action="resumeGame"};
end

function quickActionsMenu:onActionConfirmed(actionName)
    
    self:resumeGame();
    
    -- run the action
    Runtime:dispatchEvent{name="actionSelected", action=actionName, params = nil};
end



return quickActionsMenu;


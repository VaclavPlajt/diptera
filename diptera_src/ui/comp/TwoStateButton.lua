
-- two states button
local OnOffButton ={}

-- params: layer,context, cx, btnY, btnW, btnH, labelY, labelW, labelH, fontName, fontSize,
--         firstText, secondText, firstIcon, secondIcon, onFirstAction, onSecondAction,
function OnOffButton:new(params)
    
    local newPanel = {}; -- create new object
    
    -- set meta tables so lookups will work
    setmetatable(newPanel, self)
    self.__index = self
    
    
    newPanel.firstText = params.firstText;
    newPanel.secondText = params.secondText;
    
    newPanel:initButton(params);
    
    return newPanel;
end


function OnOffButton:initButton(params)
    local img = params.context.img;
    local g = params.layer;
    
    
    self.state = true; -- firts state
    self.onFirstAction = params.onFirstAction;
    self.onSecondAction = params.onSecondAction;
    
    
    self.firstBtn =img:newBtn{
            dir=params.imgDir, group=g , cx=params.cx, cy = params.btnY, hasOver = true,
            w= params.btnW, h= params.btnH,  fontSize = params.fontSize, labelColor = params.labelColor,
            name=params.firstIcon, onAction= params.onFirstAction,label = self.firstText,
        };
    
    
    
    --self.firstImg = img:newImg{dir=params.imgDir, name=params.firstIcon, group=g , cx=params.cx, cy = params.btnY, w = params.btnW, h= params.btnH}
    --self.secondImg = img:newImg{dir=params.imgDir, name=params.secondIcon, group=g , cx=params.cx, cy = params.btnY, w = params.btnW, h= params.btnH}
    
    
    self.secondBtn =img:newBtn{dir=params.imgDir,
            group=g , cx=params.cx, cy = params.btnY, hasOver= true,
            w= params.btnW, h= params.btnH, fontSize = params.fontSize, labelColor = params.labelColor,
            name=params.secondIcon, onAction= params.onSecondAction, label= self.secondText,
        };
    
    --[[
    self.label = display.newText{
        parent = g,
        text=self.firstText,
        x=params.cx,
        y=params.labelY, -- -self.divsionLineWidth,
        width=params.labelW,
        height=params.labelH,
        align = "center",
        font=params.fontName,fontSize=params.fontSize
    };]]
    
    --[[
    local btnRect = display.newRect(g, params.cx, params.cy, params.w, params.h);
    btnRect:addEventListener("tap", function(event) self:onTap(event) end);
    btnRect.isVisible = false;
    btnRect.isHitTestable = true;
    ]]
end


function OnOffButton:setFirstState()
    self.state = true; -- firts state
    --self.firstImg.isVisible = true;
    self.firstBtn.isVisible = true;
    self.firstBtn:setEnabled(true);
    --self.label.text = self.firstText;
    
    --self.secondImg.isVisible = false;
    self.secondBtn:setEnabled(false);
    self.secondBtn.isVisible = false;
end

function OnOffButton:setSecondState()
    self.state = false; -- firts state
    --self.secondImg.isVisible = true;
    self.secondBtn.isVisible = true;
    self.secondBtn:setEnabled(true);
    --self.label.text = self.secondText;
    
    --self.firstImg.isVisible = false;
    self.firstBtn:setEnabled(false);
    self.firstBtn.isVisible = false;
end

function OnOffButton:onTap(event)
    
    if(self.state) then
        self.onFirstAction();
    else
        self.onSecondAction();
    end
    
end


return OnOffButton;


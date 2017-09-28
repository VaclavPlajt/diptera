local InGameInfoPanel = {}


function InGameInfoPanel:new(x,y,layer,context, count, icon, text, iconAspect)
    
    local newIngameInfo = {};
    
    -- set meta tables so lookups will work
    setmetatable(newIngameInfo, self)
    self.__index = self
    
    
    --newIngameInfo.uiUtils = require("ui.uiUtils");
    --print("InGameInfoPanel:new(x,y,layer,context, count, icon, text)");

    newIngameInfo:init(x,y,layer,context, count, icon, text, iconAspect)
    
    return newIngameInfo;
end


function InGameInfoPanel:init(x,y,layer,context, count, icon, text, iconAspect)
        
    local uiConst = context.uiConst;
    local fontSize =  uiConst.bigFontSize;
    local iconHeight = fontSize+20;
    local iconWidth =  iconHeight * (iconAspect or 1);
    local margin = uiConst.defaultMargin;
    local backH;
    if(icon) then
        backH= iconHeight+2*margin; --1.3*fontSize;
    else
        backH= fontSize+2*margin; --1.3*fontSize;
    end
    
    local w =0; -- width is unknown util all texts are created
    
    
    
       
    local g = display.newGroup();
    layer:insert(g);
    self.g = g;
    
    -- add backround
    local back = display.newRoundedRect(g, x, y, 100, backH, 5)
    back:setFillColor(0.3,0.3,0.3,0.75);
    back.stroke = {type="image", filename= "img/comm/fuzy_stroke.png"};
    back.strokeWidth = 4;
    --back:setStrokeColor(unpack(uiConst.highlightedFontColor));
    back:setStrokeColor(0,0,0);
    back.blendMOde = "multiply";
    
    if(count) then
        self.countLabel  = display.newText{ -- contracted or tips label
            text= tostring(count),
            parent = g,
            x = x,
            y = y,
            height = 0,
            font= uiConst.fontName,
            fontSize = fontSize,
            align = "center"
        }
        self.countLabel.blendMode = "add";
        self.countLabel:setFillColor(unpack(uiConst.highlightedFontColor));
        g:insert(self.countLabel);
        w = w +self.countLabel.width + margin;
    end
    
    if(icon) then
        --local iconSize = fontSize;
        self.icon = display.newImageRect(g, icon, iconWidth, iconHeight);
        self.icon.y =y;
        w = w + self.icon.width+ margin;
    end
    
    if(text) then
        -- add label
        self.label  = display.newText{ -- contracted or tips label
            text= text,
            parent = self.g,
            x = x,
            y = y,
            --width = w,
            height = 0,
            font= uiConst.fontName,
            fontSize = fontSize,
            align = "center"
        }
        self.label.blendMode = "add";
        self.label:setFillColor(unpack(uiConst.highlightedFontColor));
        g:insert(self.label);
        w = w +self.label.width+ margin;
    end
    
    -- now the width is known, so position elements properly
    -- it cluld be done as array of compnets, but m'I lazy now
    local xx = x - 0.5*w + margin;
    
    
    if(count) then
        self.countLabel.x = xx + 0.5*self.countLabel.width;
        xx = xx + self.countLabel.width+margin;
    end
    
    if(icon) then
        self.icon.x = xx + 0.5*self.icon.width;
        xx = xx + self.icon.width + margin;
    end
    
    if(text) then
        self.label.x = xx+ 0.5*self.label.width;
        --xx = 
    end
    
    
    back.width = w + margin;

    g.alpha = 0;
    
    transition.to(self.g,{alpha=1, time = 250, transition =  easing.inOutSine});
end


function InGameInfoPanel:fadeOut()
    
    
    if(self.g== nil) then return; end;
    
    local time = 850;
    transition.to(self.g, {alpha=0, delay=4*time,  time = time, onComplete = 
        function()
            self:destroy();
        end
    })

end


function InGameInfoPanel:destroy()
    if(self.g) then
        self.g:removeSelf();
        self.g = nil;
    end
end

return InGameInfoPanel;


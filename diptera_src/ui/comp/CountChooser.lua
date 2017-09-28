
-- integer count chooser
local CountChooser = {}

-- params: layer,context, left, top, h, onCountChoosen, fontName, fontSize
function CountChooser:new(params)
    
    local newCountChooser = {}; -- create new object
    
    -- set meta tables so lookups will work
    setmetatable(newCountChooser, self)
    self.__index = self
    
    
    newCountChooser.count =0;
    
    newCountChooser:initCountChooser(params);
    
    return newCountChooser;
end


function CountChooser:initCountChooser(params)
    local uiConst = params.context.uiConst;
    local margin = uiConst.defaultMargin;
    local img = params.context.img;
    local g = params.layer;
    local fontSize = params.context.uiConst.bigFontSize;
    
    local cy = params.top + 0.5*params.h;
    local btnSize = (params.h - 2*margin)*0.75;
    local cx = params.left + margin + 0.5*btnSize;
    local dx = btnSize + margin;
    
    
    local btnPars = {dir = "ui/actions", imgName="btn_back", g=g,
        cy=cy,cx = cx, dx=dx, btnSize=btnSize, 
        labelColor = uiConst.defaultBtnLabelColor,
        }
    
    -- add ok cancel button
    local s = params.context.textSource:getText("act.material_transp_cancel");
    local btn=img:newBtn{dir=btnPars.dir,name=btnPars.imgName,group=btnPars.g,cx=btnPars.cx, cy=btnPars.cy,
    w=btnPars.btnSize, h=btnPars.btnSize,label=s, labelColor = uiConst.defaultBtnLabelColor, hasOver = true,
    onAction = function(event) params.onCountChoosen(event,0); self:reset(); end};
    
    btnPars.cx = btnPars.cx + btnPars.dx+2*margin;
    
    -- add -10
    self:addNumBtn(btnPars,img, -10);
    -- add -5
    self:addNumBtn(btnPars,img, -5);
    -- add -1
    self:addNumBtn(btnPars,img, -1);
    
    -- add label
    self.label = display.newText{
            parent = g,
            text="0",
            x=btnPars.cx,
            y=cy, -- -self.divsionLineWidth,
            --width=btnSize,
            --height=btnSize,
            --align = "center",
            font=params.fontName,fontSize=fontSize
        };
    g:insert(self.label);
    btnPars.cx = btnPars.cx + btnPars.dx;
    
    -- add +1
    self:addNumBtn(btnPars,img, 1);
    -- add +5
    self:addNumBtn(btnPars,img, 5);
    -- add +10
    self:addNumBtn(btnPars,img, 10);
    
    -- add ok button
    btnPars.cx = btnPars.cx + 2*margin;
    local btn=img:newBtn{dir=btnPars.dir,name=btnPars.imgName,group=btnPars.g,cx=btnPars.cx, cy=btnPars.cy,
    w=btnPars.btnSize, h=btnPars.btnSize,label="Ok", labelColor = uiConst.defaultBtnLabelColor, hasOver = true,
    onAction = function(event) params.onCountChoosen(event,self.count); self:reset(); end};
    
    self.w = btnPars.cx + 0.5*btnSize + margin;
end

function CountChooser:addNumBtn(par,img, num)
    
    local labelText;
    if(num>0) then
        labelText = "+" .. num;
    else
        labelText = tostring(num);
    end
    
    -- params: {dir= directory name, name=image name, group=display group, top=um, left= num, cx=num, cy = num,
    -- onAction=function(event), w= num, h=num, label=sting}
    -- either 'top' 'left' or 'cx' 'cy' has to be specified
    -- w,h - optional width and height parameters, button is scaled according to size of default image if not supplied
    local btn=img:newBtn{dir=par.dir,name=par.imgName,group=par.g,cx=par.cx, cy=par.cy,
    w=par.btnSize, h=par.btnSize,label=labelText, labelColor = par.labelColor,   hasOver = true, 
    onAction = function() self:add(num) end};

    par.cx = par.cx + par.dx;
end

function CountChooser:add(num)
    self.count = self.count + num;
    
    if(self.count < 0) then
        self.count = 0;
    end
    
    self.label.text = tostring(self.count);
end

function CountChooser:onCancel()
    print("cancel")
end

function CountChooser:reset()
    self.count =0;
    self.label.text = "0";
end

return CountChooser;


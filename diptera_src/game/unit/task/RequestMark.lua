
-- graphical mark of existing task request
local RequestMark = {}


function RequestMark:new(action,request)
    
    local newRequestMark = {};
    
    -- set meta tables so lookups will work
    setmetatable(newRequestMark, self);
    self.__index = self;
    
    newRequestMark.action = action;
    newRequestMark.request = request;
    
    
    return newRequestMark;
end


function RequestMark:createGraphics(layer, img, isoGrid)
    
    local imgName;
    local size = 40; local xDev=-32;
    local yDev = -32;
    
    if(self.action == "work") then
        imgName =  "img/comm/work_rqst.png";
        yDev = -64;
    elseif(self.action == "transport") then
        
        if(self.request.itemType=="Bullet") then
            imgName = "img/comm/bullet_rqst.png";
        else
            imgName = "img/comm/mat_rqst.png";
        end
        
    elseif(self.action == "repair") then
        imgName = "img/comm/rep_rsqt.png";
        
    end
    
    local x,y = isoGrid:isoToCart(self.request.gr, self.request.gu);
    local image =  display.newImageRect(layer,imgName, 1,1)
    image.x = x;
    image.y = y;
    image.rotation = 540;
    
    transition.to(image, {x=x+xDev, y= y+yDev, rotation = 0, width=size, height= size, time = 550} )
    self.x = x; self.y = y;
    self.dispObj = image;
end

function RequestMark:remove()
    
    if(self.dispObj == nil) then return; end
    
    transition.cancel(self.dispObj);
    transition.to(self.dispObj, { width=1, height=1, time = 250,  onComplete = 
    function()
        if(self.dispObj and self.dispObj.removeSelf) then
            self.dispObj:removeSelf(); 
            self.dispObj = nil;
        end
    end,
    --transition = easing.inBack
    });
end







return RequestMark;


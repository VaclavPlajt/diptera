local Stars = {};

local rnd = math.random;

function Stars:new(layer, minX, minY, maxX, maxY, count)

    local newStars= {};
    
    -- set meta tables so lookups will work
    setmetatable(newStars, self);
    self.__index = self
    
    self:int(layer, minX, minY, maxX, maxY, count);
    
    return newStars;
end




function Stars:int(layer, minX, minY, maxX, maxY, count)
    
    local g = display.newGroup();
    layer:insert(g);
    self.g = g;
    
    local maxSize = 40;
    local minSize = 16;
    
    local stars = {};
    
    
    for i=1,count do
        local s = minSize + rnd()*(maxSize-minSize);
        local star = display.newImageRect(g,"img/comm/star.png",s,s);
        star.x = rnd(minX,maxX)
        star.y = rnd(minY,maxY)
        star.rotation = rnd(-45 ,45);
        star.alpha = 0.4 + rnd()*0.3;
        star:setFillColor(0.7,0.7,0.9);
        
        stars[#stars+1] = star;
    end
    
    self.stars = stars;
    
    
    self:animate();
    
end



function Stars:animate()
    
    local star = self.stars[rnd(1,#self.stars)];
    
    local time = rnd(200, 500);
    local alpha = star.alpha;
    
    transition.to(star, {alpha = 1, time= 0.5*time, onComplete = 
        function()
            transition.to(star, {alpha = alpha, time= time, onComplete = 
                function()
                    self:animate();
                end
            });
        end
    });
    
end


function Stars:destroy()
    
    if(self.starts) then
        
        for i,star in ipairs(self.stars) do
            transition.cancel(star);
        end
        
        self.starts = nil;
    end
    
    
    if(self.g) then
        self.g:removeSelf();
        self.g = nil;
    end
    
end












return Stars;


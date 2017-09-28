
local MiniMap ={}


--[[ 
    params: {
    mapSize=number of tiles in right and up,
    tileW=tile width, tile height = tileW/2,
    cx = grid center position X coordinate,
    cx = grid center position Y coordinate,
    }
]]
function MiniMap:new(layer,params,context)
    
    local newMiniMap = {};
    
    setmetatable(newMiniMap, self);
    self.__index = self; 
    
    newMiniMap.layer =layer;
    newMiniMap.context = context;
    --newMiniMap.uiConst = context.uiConst;
    --newMiniMap.bounds = context.displayBounds;
    newMiniMap.onSelection = params.onSelection;
    
    newMiniMap:init(params);
    
    return newMiniMap;
end


function MiniMap:init(params)
    
    if(params.mapSize % 2 ~= 1) then
        error("Minimap size have to be an odd number not: " .. tostring(params.mapSize));
    end
    
    --local layer = self.layer;
    local g = display.newGroup();
    self.layer:insert(g);
    self.g = g;
    local uiConst = self.context.uiConst;
    local img = self.context.img;
    local tileW = params.tileW;
    local size = params.mapSize;
    local floor = math.floor;
    
    -- create small isometric grid
    local cx, cy = params.cx, params.cy;
    params.cx, params.cy = 0,0;
    local isoGrid = require("game.map.IsometricGrid"):new(params)
    self.isoGrid = isoGrid;
    --params.cx, params.cy = cx,cy;
    g.x = cx;
    g.y = cy;
    self.cy = cy;
    
    -- add back polygon for highloghts/disabled states
    local border = 0;
    local poly = display.newPolygon(g, 0, 0, 
    {isoGrid.minX-border, isoGrid.centerY, isoGrid.centerX, isoGrid.minY-border, isoGrid.maxX+border, isoGrid.centerY, isoGrid.centerX, isoGrid.maxY+border}
    );
    
    self.highlightPoly = poly;
    
    --poly.alpha = 0;
    
    local uiUtils = require("ui.uiUtils");
    self.backPolygon = uiUtils.mapBackground(g, isoGrid, uiConst);
    self.backPolygon.x =0;
    self.backPolygon.y =0;
    
    -- add ground polygon first
    --self:addGroundPolygon(layer, isoGrid, uiConst, self.backPolygon)
    
    -- add ownwer mark
    local ownerMark = display.newPolygon(g, isoGrid.centerX, isoGrid.centerY, 
    {isoGrid.minX, isoGrid.centerY, isoGrid.centerX, isoGrid.minY, isoGrid.maxX, isoGrid.centerY, isoGrid.centerX, isoGrid.maxY}
    );
    
    local fileName;
    if(isoGrid.size <= 5) then
        fileName = "img/comm/patt2_s.png";
    else
        fileName =  "img/comm/patt2.png";
    end
    
    ownerMark.fill = {type="image", filename=fileName}
    
    uiUtils.setShapePolyStyle(ownerMark, not params.cleared, uiConst);
    
    -- add disiease marks
    if(not params.cleared) then
        self:addDisMarks(isoGrid, tileW);
    end
    
    -- add item
    if(params.items) then
        self:addItems(params.items, img, isoGrid, tileW);
    end
    
    -- add home keep to central tile
    local cru = floor(size*0.5)+1;
    local x,y = isoGrid:isoToCart(cru, cru);
    local keepName;
    if(params.cleared) then
        if(params.powerCat == "home") then
            keepName = "home.png";
        else
            keepName = "cat" .. params.powerCat .. ".png";
        end
        
    else
        if(params.powerCat == "home") then
            keepName = "home_covered.png";
        else
            keepName= "cat" .. params.powerCat .. "_covered.png";
        end
    end
    
    local keepSize = tileW *1.5;
    self.keep = img:newTileImg{group=g,w=keepSize, h=keepSize, dir= "keep", name=keepName, cx=x, cy = y}
    self.x, self.y = isoGrid.centerX, isoGrid.centerY
    
    -- add item
    if(params.items) then
        self:addItems(params.items, img, isoGrid, tileW, params.cleared);
    end
    
    self.backPolygon:addEventListener("tap", function() return self:onTap(); end);
    self:setHigllightState(params.selectable);
    self.isAcessible = params.selectable;
end

function MiniMap:setHigllightState(state)
    local poly = self.highlightPoly;
    self.higllightState = state;
    
    if(state) then
        poly:toBack();
        poly:setFillColor(0.4, 0.05, 0.1);
        poly.blendMode="add";
        poly.alpha = 0;
    else
        poly:toFront();
        poly:setFillColor(0.5, 0.5, 0.5,0.5);
        
        --poly.alpha = 0.5;
        poly.blendMode="normal";
    end
    
end


function MiniMap:addItems(items, img, isoGrid, tileW, cleared)
    --items = {{name="Material",r=1,u=1}, {name="Bullet",r=2,u=1}, {name="Treasure", r=3, u=1} },
    
    tileW = tileW *0.75;
    
    for i,itemDef in ipairs(items) do
        -- select image
        local name = itemDef.name;
        local imgName;
        local dir;
        
        if(name=="Material") then
            dir = "material";
            imgName = "mat_100.png";
        elseif(name=="Bullet") then
            dir = "gun";
            imgName = "bullet.png";
        elseif(name=="Treasure") then
            if(not cleared) then
                dir = "treasure";
                imgName = "treasure.png";
            end
        --elseif(name=="") then
        else
            print("Warning unknown mini map item name: ".. tostring(name))
        end
        
        if(imgName) then
            local x,y = isoGrid:isoToCart(itemDef.r, itemDef.u);
            img:newTileImg{group=self.g,w=tileW, h=tileW, dir= dir, name=imgName, cx=x, cy = y}
        end
        
    end
end

function MiniMap:addDisMarks(isoGrid, tileW)
    local maxSize = 6;
    local minSize = 3;
    local mapSize = isoGrid.size;
    local count = mapSize*3;
    local rnd = math.random;
    
    
    for i=1, count do
        -- get random coords
        local x,y = isoGrid:isoToCart(rnd(1,mapSize-1), rnd(1,mapSize-1));
        -- add random shift inside tile
        x,y = x+rnd()*0.5*tileW, y+rnd()*0.25*tileW;
        
        -- add mark
        local s = rnd(minSize, maxSize);
        local mark = display.newImageRect(self.g, "img/comm/dis_small.png", s, s);
        mark.x, mark.y = x, y;
        --print("Adding dis mark of size " .. s)
    end
    
end

--[[
function MiniMap:addGroundPolygon(layer, isoGrid, uiConst)
    
    local depth = isoGrid.height*0.5;
    local wp, hp = 0.5*isoGrid.width, 0.5*isoGrid.height;
    --local f;-- = backPolygon.fill;
    local textureSize = uiConst.mapBackTextureSize;
    local cx, cy = isoGrid.centerX, isoGrid.centerY;
    --local sX = f.scaleX;
    --local sY = f.scaleY;
    --print("sx, sy:" .. sX .. ", " .. sY)
    
    
    
    local lGround = display.newPolygon(layer, cx-0.5*wp, cy+0.5*(hp+depth), 
    {-wp, -hp, 0, 0, 0, depth}
    );
    
    lGround.fill = {type="image", filename= "img/back.png"}
    lGround.fill.scaleX = textureSize/wp;
    lGround.fill.scaleY = textureSize/(depth+hp);
    --print("sx, sy:" .. lGround.fill.scaleX .. ", " .. lGround.fill.scaleY)
    lGround.blendMode = "add";
    lGround.alpha = uiConst.mapBackgroundAlpha;-- 0.4;
    lGround:setFillColor(0.1, 0.1,0.1)
    --lGround:setFillColor(0.399, 0.488,0.37)
    
    local rGround = display.newPolygon(layer, cx+0.5*wp, cy+0.5*(hp+depth), 
    {0, 0, wp, -hp, 0, depth}
    );
    
    --rGround:setFillColor(0.56, 0.651,0.517)
    
    rGround.fill = {type="image", filename= "img/back.png"}
    rGround.fill.scaleX =textureSize/wp;
    rGround.fill.scaleY = textureSize/(depth+hp);
    rGround.blendMode = "add";
    rGround.alpha = uiConst.mapBackgroundAlpha;-- 0.4;
    lGround:setFillColor(0.2, 0.2,0.2)
    --TODO shoft fills to match each other
    
    local line = display.newLine(layer,cx-wp,cy,cx,cy+hp,cx+wp,cy);
    line.stroke = {type="image", filename= "img/comm/fuzy_stroke.png"};
    line.strokeWidth = 3;
    line:setStrokeColor(0, 0, 0, 0.25);
    
    --self.maxY = cy+hp+depth;
    --self.minY = cy-hp;
end
]]

function MiniMap:onTap()
    self:showSelection();
    if(self.onSelection) then
        self.onSelection();
    end
    return true;
end

function MiniMap:showSelection()
    if(self.keep) then
        local o = self.g;--self.dispObj;
        --local sy = o.y;
        local h  = self.isoGrid.height;
        transition.cancel(o);
        
        
        transition.to(o, {y=self.cy-h*0.1, xScale = 1.25,yScale = 1.25, time = 150, onComplete = 
            function() transition.to(o, {y=self.cy,xScale = 1, yScale = 1, time = 100}); end,
            --onCancel = function() o.y=sy; o.xScale=1; o.yScale = 1; end,
        });
        
        
        if(self.higllightState) then
            transition.cancel(self.highlightPoly);
            
            transition.to(self.highlightPoly, {alpha=0.8, time=150, onComplete = 
                function()
                    transition.to(self.highlightPoly, {alpha=0.4, time=100});
                end
            });
        end
        
        --[[
        local dio = self.keep;
        dio.fill.effect = "filter.contrast";
        dio.fill.effect.contrast = 1;
        transition.to(dio.fill.effect,{contrast = 2.5, time = 150})
        ]]
        
    end
    
end


function MiniMap:cancelSelection()
    if(self.higllightState) then
        self.highlightPoly.alpha = 0;
    end
    
    --[[
    if(self.keep) then
        transition.cancel(self.keep);
        self.keep.fill.effect = nil;
    end
    ]]
end


return MiniMap;


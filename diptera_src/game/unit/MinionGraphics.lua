local MinionGrapics = {}

local getDirNum = require("math.geometry").getDirNum;
local showDebugInfo = false;

local workSignSize = 16;
local workSignBigSize = 64;

function MinionGrapics:new(x,y,myLayer, aboveMapLayer, img,isoGrid, minion)
    local newMinionGraphics = {};
    
    -- set meta tables so lookups will work
    setmetatable(newMinionGraphics, self)
    self.__index = self
    
    
    newMinionGraphics.minion = minion;
    newMinionGraphics.isoGrid = isoGrid;
    newMinionGraphics.aboveMapLayer = aboveMapLayer;
    --newMinionGraphics.tintColor = {1,1,1,1};
    
    newMinionGraphics.lastImgName  = nil;
    newMinionGraphics.workTypeMark = nil;
    newMinionGraphics.workMarkColor = require("ui.uiConst").humanPlayerColor;
    newMinionGraphics.workMark = nil;
    newMinionGraphics.workMarkTrans = nil;
    
    
    newMinionGraphics:initGraphics(x,y,myLayer,img);
    
    
    return newMinionGraphics;
end

function MinionGrapics:getCoord()
    --return self.dispObj.x, self.dispObj.y;
    return self.g.x, self.g.y;
end



function MinionGrapics:initGraphics(x,y,layer,img)
    self.layer = layer;
    self.img = img;
    self.workTypeName = "?";
    
    local g =  display.newGroup();
    layer:insert(g)
    self.g = g;
    
    
    
    if(showDebugInfo) then
        self.label = display.newText("", 0, 32, native.systemFont, 14 );
        
        --self.dirMark = display.newCircle(g, 0, 0, 3);
        --myText:setFillColor(0.9,0.3,0.2,1);
        g:insert(self.label);
    end
    
    self.lastDirNum = math.random(1,8);
    
    g.x = x;
    g.y = y;
    self:update();
end

function MinionGrapics:update(dirNum)
    
    local dir = dirNum or self.lastDirNum;
    
    self:updateDirectionImage(dir);
    
    if(self.label) then
        self.label.text = self.workTypeName .. ":" .. string.sub(self.minion.taskState, 1,3);
        --self.dispObj:setFillColor(unpack(self.tintColor));
    end
end

function MinionGrapics:translate(x,y,time,delay, callback)
    
    
    local obj = self.g;
    --local obj = self.dispObj;
    --local cx,cy  = g:localToContent(x,y)
    local par = {x= x, y=y, time = time, onComplete = callback };
    
    if(delay > 0 ) then
        par.delay = delay;
    end
    
    self.translation = transition.to(obj, par);
    
end

function MinionGrapics:forcePosision(x,y)
    self.g.x = x;
    self.g.y = y;
end

function MinionGrapics:cancelTranslation()
    if(self.translation) then
        transition.cancel(self.translation);
        self.translation = nil;
    end
end

function MinionGrapics:removeWorkMark()
    if(self.workMark) then
        
        if(self.workMarkTrans) then
            transition.cancel(self.workMarkTrans);
            self.workMarkTrans = nil;
        end
        
        transition.cancel(self.workMark);
        self.workMark:removeSelf();
        self.workMark = nil;
    end
    
    --[[
    if(self.healEmmiter) then
        self.healEmmiter:removeSelf();
        self.healEmmiter = nil;
    end
    ]]
    
end


function MinionGrapics:setWorkingCoord(gr,gu)
    
    --print("MinionGrapics:setWorkingCoord(gr,gu): ".. tostring(gr) .. ", " .. tostring(gu));
    
    -- work done/cancelled
    if(self.workMark and (not gr or not gu)) then
        self:removeWorkMark();
        return;
    end
    
    -- work start
    if(not self.workMark and gr and gu and self.workTypeName ~= "t") then
        local x,y = self.isoGrid:isoToCart(gr,gu);
        local g = self.g;
        local gx, gy =  g:localToContent(0, 0);
        
        local workMark=nil;
        
        if(self.workTypeName == "r") then -- repairs
            
            Runtime:dispatchEvent({name="soundrequest", type="playnammed", soundName="heal", x=gx, y=gy}); -- play sound   
            local emmitter = require("ui.particles").newEmitter("heal");
            workMark = emmitter;
            self.aboveMapLayer:insert(emmitter);
            emmitter.x = x;
            emmitter.y = y-32;
            emmitter.duration =-1;
            
            
            --emitter:start()
            
            --[[
            local wg = display.newGroup();
            self.aboveMapLayer:insert(wg);
            
            local color = self.workMarkColor
            local colAlpha = {color[1],color[2],color[3], 0.5}
            local img= display.newImageRect(wg, "img/comm/repair_pattern.png", 64, 64);
            img.x = x;
            img.y = y-32;
            img:setFillColor(unpack(color));
            img.blendMode = "add";
            self.workMarkTrans = transition.to(img, {rotation=720, time=10000});
            
            
            local beam = display.newLine(wg, gx, gy-16, x, y-32);
            beam.strokeWidth = 4;
            beam:setStrokeColor(unpack(color));
            beam.alpha = 0.5;
            
            beam.blendMode = "add";
            workMark = wg;
            ]]--
        else
            --workMark = display.newLine(self.aboveMapLayer, gx, gy, x, y);
            --workMark.strokeWidth = 3;
            --[[
            workMark = display.newImageRect( self.aboveMapLayer, "img/comm/gear.png", 32, 32);
            workMark.x = x+32;
            workMark.y = y+16;
            workMark.alpha = 0.75;
            transition.to(workMark, {rotation=720, time=10000})
            ]]
            local emmitter = require("ui.particles").newEmitter("work");
            workMark = emmitter;
            self.aboveMapLayer:insert(emmitter);
            emmitter.x = x;
            emmitter.y = y;
            emmitter.duration =-1;
        end
        
        self.workMark = workMark;
        
        
        -- determine working direction
        local r, u = self.minion:getIsoCoord();
        local dirNum =  getDirNum(gr-r, gu-u)
        self:updateDirectionImage(dirNum);
    else
        self:updateDirectionImage(self.lastDirNum);
    end
    
end

--[[
-- dir - direction vector
-- dirNum - direction index, refer to require("math.geometry").eightDir
function MinionGrapics:changeDirection(dirVec, dirNum)
    
    local s = 20;
    -- eight directions coordinates changes
    -- ur, dr, dl, ul, right, down, left, up
    --geometry.eightDir = {{0,1},{1,0},{0,-1},{-1,0},{1,1},{1,-1},{-1,-1},{-1,1}}
    
    if(dirNum == 1) then -- ur
        self.dirMark.x = s;
        self.dirMark.y = -s;
    elseif(dirNum == 2) then -- dr
        self.dirMark.x = s;
        self.dirMark.y = s;
    elseif(dirNum == 3) then -- dl
        self.dirMark.x = -s;
        self.dirMark.y = s;
    elseif(dirNum == 4) then -- ul
        self.dirMark.x = -s;
        self.dirMark.y = -s;
    elseif(dirNum == 5) then -- right
        self.dirMark.x = s;
        self.dirMark.y = 0;
    elseif(dirNum == 6) then -- down 
        self.dirMark.x = 0;
        self.dirMark.y = s;
    elseif(dirNum == 7) then -- left
        self.dirMark.x = -s;
        self.dirMark.y = 0;
    elseif(dirNum == 8) then -- up
        self.dirMark.x = 0;
        self.dirMark.y = -s;
    else
        print("Warning MinionGrapics:changeDirection: unknown direction num:" .. tostring(dirNum))
    end
    
end
]]

--TODO v pripade problemu s pameti predelat na look-up tabulku
function MinionGrapics:updateDirectionImage(dirNum)
    
    
    -- eight directions coordinates changes
    -- ur, dr, dl, ul, right, down, left, up
    --geometry.eightDir = {{0,1},{1,0},{0,-1},{-1,0},{1,1},{1,-1},{-1,-1},{-1,1}}
    
    local dirStr;
    
    -- carying item ?
    local carrItemExt = nil
    local minion = self.minion;
    if(minion.taskState == "transporting" and minion.taskData) then
        local itemType = minion.taskData.typeName;
        if(itemType == "Material") then
            carrItemExt = "_mat";
        elseif(itemType == "Bullet") then
            carrItemExt = "_pamp";
        end
    end
    
    
    if(dirNum == 0) then 
        return; -- noting to change
    elseif(dirNum == 1) then -- ur
        dirStr ="_ur"
    elseif(dirNum == 2) then -- dr
        dirStr ="_dr"
    elseif(dirNum == 3) then -- dl
        dirStr ="_dl"
    elseif(dirNum == 4) then -- ul
        dirStr ="_ul"
    elseif(dirNum == 5) then -- right
        dirStr ="_right"
    elseif(dirNum == 6) then -- down 
        dirStr ="_down"
    elseif(dirNum == 7) then -- left
        dirStr ="_left"
    elseif(dirNum == 8) then -- up
        dirStr ="_up"
    else
        print("Warning, MinionGrapics:updateDirectionImage: unsuported direction num:" .. tostring(dirNum));
        return; -- no update can be done
    end
    
    self.lastDirNum = dirNum;
    local imgName;
    if(carrItemExt) then
        imgName = "m" .. dirStr ..  carrItemExt .. ".png";
    else
        imgName = "m" .. dirStr .. ".png";
    end
    
    --print("Minion image name:" .. imgName);
    
    if(self.lastImgName ~= imgName) then
        if(self.dispObj) then self.dispObj:removeSelf() end;
        
        self.dispObj = self.img:newTileImg{w=128, h=64, dir= "minion", name=imgName, group=self.g, cx=0, cy = 0}
        self.dispObj:toBack();
        --self.dispObj:setFillColor(unpack(self.tintColor));
    end
    
end


function MinionGrapics:setWorkType(workType)
    local imgName= nil;
    local lastWorkName = self.workTypeName;
    
    if(workType == "work") then
        imgName =  "img/comm/work_rqst.png";
        self.workTypeName = "w";
    elseif(workType == "transport") then
        imgName = "img/comm/mat_rqst.png";
        self.workTypeName = "t";
        
    elseif(workType == "repair") then
        
        imgName = "img/comm/rep_rsqt.png";
        self.workTypeName = "r";
    elseif(workType == "idle") then
        self.workTypeName = "i";
    else
        print("minon: unknown work type:".. tostring(workType));
    end
    
    if(lastWorkName ~= self.workTypeName) then
        
        self:update();
        
        if(self.workTypeMark) then 
            self.workTypeMark:removeSelf();
            self.workTypeMark = nil;
        end;
        
        
        if(imgName) then
            --[[
            self.workTypeMark = display.newImageRect(self.g, imgName, workSignSize, workSignSize)
            self.workTypeMark.x = 0;-- -1.2*workSignSize;
            self.workTypeMark.y = workSignSize;
            ]]
            local g = self.g;
            local above = self.aboveMapLayer;
            
            local mark = display.newImageRect(above, imgName, workSignSize, workSignSize)
            self.workTypeMark = mark;
            --mark.x = 0;-- -1.2*workSignSize;
            --mark.y = 0;
            local x, y = g:localToContent(0,0);
            x,y = above:contentToLocal(x,y);
            mark.x, mark.y = x, y;
            
            --print("x,y:" .. x .. ", " .. y );
            local locX, locY = 0.5*workSignBigSize,-workSignBigSize;
            
            x, y = g:localToContent(locX, locY);
            x,y = above:contentToLocal(x,y);
            
            self.workMarkTrans=transition.to(mark, {width = workSignBigSize, height = workSignBigSize, x=x, y=y,
                time=250, rotation=360, onComplete = 
                function()
                    --g:insert(mark);
                    --mark.x , mark.y  =locX, locY;
                    
                    x,y = g:localToContent(0, workSignSize);
                    x,y = above:contentToLocal(x,y);
                    
                    self.workMarkTrans=transition.to(mark, {width = workSignSize, height = workSignSize, x= x, y= y, rotation=0,
                        time = 250, delay = 400, onComplete=
                        function()
                            if(self.workTypeMark)then
                                g:insert(mark);
                                mark.x , mark.y  =0, workSignSize;
                            end
                        end
                    });
                    
                end
            });
            
            --workSignBigSize
            
        end
    end
    
end

-- path visualization for debugging purpouses
function MinionGrapics:showPath(path)
    
    if(self.pathGroup) then
        self.pathGroup:removeSelf();
    end
    
    
    local group = display.newGroup();
    self.layer:insert(group);
    self.pathGroup = group;
    local isoGrid = self.isoGrid;
    local nodeData;
    --local tileW = self.isoGrid.tileW;
    
    -- render open map
    local color  = {0,0,0.8,0.5};
    
    local dirImages= {"1_ur", "2_dr", "3_dl", "4_ul", "5_right", "6_down", "7_left", "8_up"};
    
    -- render line along path
    if(#path > 1) then
        local lineData = {}
        for i= 1, #path do
            
            nodeData = path[i];
            local x,y = isoGrid:isoToCart(nodeData[1], nodeData[2]);
            
            lineData[#lineData + 1] = x;
            lineData[#lineData + 1] = y;
            
            if(nodeData[7] > 0) then
                local nodeImg = self.img:newImg{dir= "mockup", name=dirImages[nodeData[7]], group=group, cx=x, cy = y};
            end
            --print("way point r,u: " .. nodeData[1] .. ", " .. nodeData[2])
        end
        
        local pathLine = display.newLine(group,unpack(lineData));
        pathLine.strokeWidth = 2;
        --pathLine:setStrokeColor(0.9, 0.2,0.2);
        --pathLine:setStrokeColor( unpack(self.tintColor));
    end
    
end


return MinionGrapics;


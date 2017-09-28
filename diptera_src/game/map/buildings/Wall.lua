
-- base class for all buildings
local Wall = {};


setmetatable(Wall, require("game.map.buildings.Building"))
Wall.__index = Wall

Wall.iconDir = "img/walls/"
Wall.icon = "W.png";

function Wall:new(r,u,map)
    local gameConst = require("game.gameConst");
    local WallDef =  gameConst.Wall;
    
    local newWall = require("game.map.buildings.Building"):new("Wall",r, u, map,WallDef.toughness);
    
    -- set meta tables so lookups will work
    setmetatable(newWall, self)
    self.__index = self
    
    
    -- let others know
    newWall:dispatchBuildingCreatedEvent()
    newWall.repairRequestLimit = math.ceil(newWall.toughness*WallDef.repairRequestLimitMultip);
    --newWall.searching = false;
    
    return newWall;
end

function Wall:updateGraphics()
    if(self.label) then
        self.label.text = tostring(self.fitness);
    end
end

-- will look at neighborhood in map and chooses right shape (image) of wall
-- NOTE: I tried to do this as lookup table, but it was equally complicated
function Wall:getWallImgName(notifyOthers)
    
    local ul,ur,dr,dl = self:searchNeighborhood(notifyOthers);
    
    if(ul) then
        if(ur) then
            if(dr) then
                if(dl) then
                    return "W_ul_ur_dr_dl.png";
                else -- dl == false
                    return "W_ul_ur_dr.png"
                end
            else -- dr == false
                if(dl) then
                    return "W_ul_ur_dl.png"
                else -- dl == false
                    return "W_ul_ur.png"
                end
            end
        else -- ur == false
            if(dr) then
                if(dl) then
                    return "W_ul_dr_dl.png"
                else -- dl == false
                    return "W_ul_dr.png"
                end
            else -- dr == false
                if(dl) then
                    return "W_ul_dl.png"
                else -- dl == false
                    return "W_ul_dr.png"; -- should be "W_ul" only, but this is not supported
                end
            end
        end
    else -- ul == false
        if(ur) then
            if(dr) then
                if(dl) then
                    return "W_ur_dr_dl.png";
                else -- dl == false
                    return "W_ur_dr.png";
                end
            else -- dr == false
                if(dl) then
                    return "W_ur_dl.png";
                else -- dl == false
                    return "W_ur_dl.png" ; -- should be "W_ur" only, but this is not supported
                end
            end
        else -- ur == false
            if(dr) then
                if(dl) then
                    return "W_dl_dr.png" -- mistakenly named blender camera
                else -- dl == false
                    return "W_ul_dr.png"; -- should be "W_dr" only, but this is not supported
                end
            else -- dr == false
                if(dl) then
                    return "W_ur_dl.png"; -- should be "W_dl" only, but this is not supported
                else -- dl == false
                    return "W.png"
                end
            end
        end
    end
    
end

-- returns ul,ur,dr,dl - boolean variables, true when another wall in direction
function Wall:searchNeighborhood(notifyOthers)
    --self.searching = true;
    local r,u = self.r, self.u;
    local map = self.map;
    local size = map.size;
    local tiles = map.tiles;
    local itemsById = map.itemsById;
    local ul,ur,dr,dl;
    
    local tr, tu; -- temporarry coordinates
    local item;
    
    -- look up-left
    tr = r -1; tu = u;
    if(tr > 0 and tr <= size and tu > 0 and tu <= size and tiles[tr][tu].item > 0) then
        item = itemsById[tiles[tr][tu].item];
        if(item.typeName == "Wall") then
            ul = true;
            if(notifyOthers) then  item:neightChanged(); end;-- notify wall about this new wall
        end
    end
    
    -- look up-right
    tr = r; tu = u+1;
    if(tr > 0 and tr <= size and tu > 0 and tu <= size and tiles[tr][tu].item > 0) then
        item = itemsById[tiles[tr][tu].item];
        if(item.typeName == "Wall") then
            ur = true;
            if(notifyOthers) then  item:neightChanged(); end;-- notify wall about this new wall
        end
    end
    
    -- look down-right
    tr = r+1; tu = u;
    if(tr > 0 and tr <= size and tu > 0 and tu <= size and tiles[tr][tu].item > 0) then
        item = itemsById[tiles[tr][tu].item];
        if(item.typeName == "Wall") then
            dr = true;
            if(notifyOthers) then  item:neightChanged(); end;-- notify wall about this new wall
        end
    end
    
    -- look down-left
    tr = r; tu = u-1;
    if(tr > 0 and tr <= size and tu > 0 and tu <= size and  tiles[tr][tu].item > 0) then
        item = itemsById[tiles[tr][tu].item];
        if(item.typeName == "Wall") then
            dl = true;
            if(notifyOthers) then  item:neightChanged(); end;-- notify wall about this new wall
        end
    end
    
    --self.searching = false;
    
    return ul,ur,dr,dl;
end



-- tells this wall, that new wall is build in neighborhood
function Wall:neightChanged()
    if(not self.dispObj) then return; end
    
    local imgName = self:getWallImgName(false);
    if(imgName == self.usedImg) then return; end;    
    self.usedImg = imgName;
    
    -- recreate wall image
    self.dispObj:removeSelf();
    local map = self.map;
    local tileW = map.isoGrid.tileW;
    --local size = map.size;
    --local renderIndex = map.tiles[self.r][self.u].renderIndex;
    
    
    self.dispObj = self.img:newTileImg{w=tileW, h=tileW, dir= "walls", name=imgName, cx=self.x, cy = self.y}--, group=self.layer}
    self:insertToCalcIndex(self.layer,self.dispObj);
end

function Wall:initGraphics(x,y,layer, img, mapDebugLayer)
    self.layer= layer;
    self.img = img;
    self.x= x;
    self.y = y;
    local imgName = self:getWallImgName(true);
    self.usedImg = imgName;
    local map = self.map;
    local tileW = map.isoGrid.tileW;
    --local renderIndex = map.tiles[self.r][self.u].renderIndex;
    
    self.dispObj = img:newTileImg{w=tileW, h=tileW, dir= "walls", name=imgName, cx=x, cy = y}--, group=layer}
    self:insertToCalcIndex(self.layer,self.dispObj);
    
    if(mapDebugLayer) then
        self.label = display.newText("" .. self.fitness, x, y, native.systemFont, 14 )
        mapDebugLayer:insert(self.label);
    end
    
end

function Wall:destroy()
    if(self.destroyed) then return; end;
    self.destroyed = true;
    self.map:removeItem(self);
    --print("Warning default implementation of Building:destroyed() -  does nothing");
    self.dispObj:removeSelf();
    self.dispObj = nil;
    if(self.label) then self.label:removeSelf(); self.label = nil; end
    
    if(self.lastHitEmmiter) then
        self.lastHitEmmiter:removeSelf();
        self.lastHitEmmiter = nil;
    end
    
    self:searchNeighborhood(true);
    
end

return Wall;




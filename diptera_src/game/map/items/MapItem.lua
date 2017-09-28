-- base class for item on map

local MapItem  = {}

MapItem.infoProperties = {};
--MapItem.infoProperties = {"renderIndex", "usedIndex"}; -- properties to show in infoPanel
MapItem.iconDir = "img/mockup/"
MapItem.icon = "empty"; -- icon to show in InfoPanel

function MapItem:new(typeName, r, u, map)
    
    local newMapItem = {};
    
    -- set meta tables so lookups will work
    setmetatable(newMapItem, self)
    self.__index = self
    
    newMapItem.typeName = typeName;
    newMapItem.r = r;
    newMapItem.u = u;
    newMapItem.map = map;
    newMapItem.id = map:addItem(newMapItem);
    --newMapItem.renderIndex = map.tiles[r][u].renderIndex;
    --newMapItem.usedIndex = -1;
    
    return newMapItem;
end

-- calculates render index, based on tile render index, max render index and number of childrens in given group
function MapItem:insertToCalcIndex(group, dispObject)
    
    local index = self.map:getRenderIndex(self);
    --[[
    print("numOfChildren: " .. group.numChildren .. ", renderIndex: " .. self.renderIndex .. 
            ", maxRenderIndex: " .. self.map.maxRenderIndex .. ", usedIndex = " .. index);
    self.usedIndex = index;
    ]]
    
    group:insert(index, dispObject);
end


function MapItem:initGraphics(x,y,layer, img, mapDebugLayer)
    print("Warning default implementation of MapItem:initGraphics() -  does nothing");
end

function MapItem:showSelection()
    if(self.dispObj and not self.selTrans) then
        local o = self.dispObj;
        
        --transition.cancel(o);
        local sy =o.y;
        
        
        self.selTrans = transition.to(o, {y=sy-o.height*0.1, xScale = 1.25,yScale = 1.25, time = 150,
            --onCancel = function() print("ccc"); o.y=sy; o.xScale = 1; o.yScale = 1; end,
            onComplete =  function()
                self.selTrans = transition.to(o, {y=sy,xScale = 1, yScale = 1, time = 100, onComplete = 
                    function()
                        self.selTrans = nil;
                    end
                }); 
            end
        });
        
    end
end

function MapItem:onSelection()
    --print("Warning default: MapItem:onSelection() - does nothing");
    self:showSelection();
end

return MapItem;


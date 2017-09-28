
local BuildingsList = {};



function BuildingsList:new(layer, context,gameConst, top, left)
    
    local newBuildingsList = {};
    
    -- set meta tables so lookups will work
    setmetatable(newBuildingsList, self)
    self.__index = self;
    
    newBuildingsList.context = context;
    newBuildingsList.layer= layer;
    
    newBuildingsList:init(layer, context,gameConst, top, left);
    
    
    return newBuildingsList;
end

function BuildingsList:getListDef(context,gameConst)
    local textSource = context.textSource;
    
    local wallModule = require("game.map.buildings.Wall");
    local gunModule  = require("game.map.buildings.Gun") 
    
    local list= {
        -- add wall
        {
            icon = wallModule.iconDir .. wallModule.icon,
            name = textSource:getText("actions.wallTitle"),
            materialCost = gameConst.Wall.materialCost
        },
        --add wall
        {
            icon = gunModule.iconDir .. gunModule.icon,
            name = textSource:getText("actions.GunTitle"),
            materialCost = gameConst.Gun.materialCost
        }
    }
    
    return list;
end

function BuildingsList:init(layer, context,gameConst, top, left)
    
    local uiConst = context.uiConst;
    
    local list = self:getListDef(context,gameConst);
    
    local iconSize = uiConst.mapTileWidth*0.5;
    local margin = uiConst.defaultMargin;
    local nameTextSize = uiConst.bigFontSize;
    local textSize = uiConst.normalFontSize;
    
    local g = display.newGroup();
    layer:insert(g);
    
    local x, y;
    x = left + margin;
    y = top + 0.5*nameTextSize;
    
    -- add title
    local titleLabel  = display.newText{
        text= context.textSource:getText("help.buildingListTitle"),
        parent = g,
        x = x,
        y = y,--+0.5*nameTextSize,
        --width = w,
        font= uiConst.fontName,
        fontSize = nameTextSize,
        align = "left"
    }
    titleLabel:setFillColor(unpack(uiConst.defaultFontColor))
    titleLabel.anchorX = 0;
    
    local line = display.newLine(g, x, top+nameTextSize+margin, x+titleLabel.width, top+nameTextSize+margin);
    line.strokeWidth = 2;
    line:setStrokeColor(unpack(uiConst.clusterEdgeColor));
    line.blendMode = "add";
    
    y = top+nameTextSize+2*margin + 0.5*iconSize+2;
    local maxW = 0;
    --print("predjizda")
    
    for i,def in ipairs(list) do
        x = left + margin;
        
        
        -- add icon background
        local back = display.newRoundedRect(g, x + 0.5*iconSize, y, iconSize, iconSize, 5);
        back:setFillColor(unpack(uiConst.defBtnFillColor.default))
        back.blendMode = "add";
        
        -- add icon image
        local icon = display.newImageRect(g, def.icon, iconSize, iconSize);
        icon.x = x + 0.5*iconSize;
        icon.y = y;
        
        x = x + iconSize + margin;
        
        -- add name
        local nameLabel  = display.newText{
            text= def.name,
            parent = g,
            x = x,
            y = y-0.25*iconSize,--+0.5*nameTextSize,
            --width = w,
            font= uiConst.fontName,
            fontSize = nameTextSize,
            align = "left"
        }
        nameLabel:setFillColor(unpack(uiConst.defaultFontColor))
        nameLabel.anchorX = 0;
        
        if(nameLabel.width > maxW) then maxW = nameLabel.width end;
        
        -- add material cost
        local costLabel  = display.newText{
            text= tostring(def.materialCost) .. " x",
            parent = g,
            x = x,
            y = y+0.25*iconSize,--+0.5*nameTextSize,
            --width = w,
            font= uiConst.fontName,
            fontSize = textSize,
            align = "left"
        }
        costLabel:setFillColor(unpack(uiConst.defaultFontColor))
        costLabel.anchorX = 0;
        
        if(costLabel.width > maxW) then maxW = costLabel.width end;
        
        -- add material icon
        local matIcon = display.newImageRect(g, "img/comm/mat_rqst.png", textSize, textSize);
        matIcon.x = costLabel.x + costLabel.width + margin+0.5*textSize;
        matIcon.y = costLabel.y;
        
        y = y + margin + iconSize;
    end
    
end















return BuildingsList;



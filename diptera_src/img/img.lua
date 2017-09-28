-- image loading module

local img = {}

local basePath = "img/"

--[[
local configFile = "images.json";
local indexFile = "dir-index.json";



local function getTableFormFile(filename)
    local dataTable=nil;    
    local jsonString;
    local json = require("json");
    
    -- check whenewer levelstate file exists
    --local filePath = filename;--system.pathForFile( filename, system.DocumentsDirectory )
    local filePath = system.pathForFile( filename, system.ResourceDirectory );
    local file = io.open( filePath, "r" )  --check if the file already exists
    
    
    if file then -- read level states from file
        jsonString = file:read("*a");
        dataTable = json.decode(jsonString);
        io.close(file);
    end
    
    
    return dataTable;
end

function img:create()
    if(not self.dirConfigs) then
        -- load dir-index
        local dirList = getTableFormFile(basePath .. indexFile);
        
        local dir;
        local dirConfigs = {}
        local config;
        
        for i=1,#dirList do
            dir = dirList[i];
            config = getTableFormFile(basePath .. dir .. "/" .. configFile);
            dirConfigs[dir] = config;
            
        end
        
        self.dirConfigs = dirConfigs;
        
    end
    
    return img;
end


-- creates new image from given parameters
-- params: {dir= directory name, name=image name, group=display group, top=um, left= num, cx=num, cy = num, w= num, h= num}
-- either 'top' 'left' or 'cx' 'cy' has to be specified
--- w,h (width, height) - are optional size parameters
function img:newImg(params)
    
    local dir = params.dir;
    assert(dir, "Cannot create image without specified directory!" );
    
    local name = params.name;
    assert(name, "Cannot create image without specified name!");
    
    local def = self.dirConfigs[dir][name];
    
    assert(def, "No image with name " .. name .. " found.");
    
    local group=params.group;
    
    local w = params.w or def.w;
    local h = params.h or def.h;
    local x,y;
    
    if(params.top and params.left) then
        x = params.left + 0.5*w;
        y= params.top + 0.5*h;
    elseif(params.cx and params.cy) then
        x = params.cx;
        y = params.cy;
    else
        error("No image position specified! Params has to contan either 'top' 'left' or 'cx' 'cy' coordinates.");
    end
    
    
    local image;
    if(group) then 
        image = display.newImageRect(group, basePath .. dir .. "/" .. def.file, w, h);
    else
        image = display.newImageRect(basePath .. dir .. "/" .. def.file, w, h);
    end
    
    image.x = x;
    image.y = y;    
    
    return image;
end
]]

-- creates new map tile image from given parameters
-- params: {dir= directory name, name=tile name, w= width, h= height group=display group,cx=num, cy = num}
-- 'cx' 'cy' are coordinates of tile center and has to be specified
function img:newTileImg(params)
    
    local dir = params.dir;
    assert(dir, "Cannot create tail image without specified directory!" );
    
    local name = params.name;
    assert(name, "Cannot create taile image without specified name!");
    
    --local def = self.dirConfigs[dir][name];
    --assert(def, "No image with name " .. name .. " found.");
    
    local group=params.group;
    
    assert(params.w, "Tile image need to have specified width.")
    assert(params.h, "Tile image need to have specified height.")
    assert(params.cx,  "Tiles center coordinates (cx,cy) have to be specified!")
    assert(params.cy,  "Tiles center coordinates (cx,cy) have to be specified!")
    
    
    local image;
    if(group) then 
        image = display.newImageRect(group, basePath .. dir .. "/" .. name, params.w, params.h);
    else
        image = display.newImageRect(basePath .. dir .. "/" .. name, params.w, params.h);
    end
    
    image.x = params.cx;
    
    -- if tile image height is heigher than 0.5 tile width,
    --- image centerpoint needs to be shifted up form tile center
    local y;
    if(params.h > params.w*0.5)then
        y = params.cy - (params.h - 0.5*params.w)*0.5; 
    else
        y = params.cy; 
    end
    --[[]
    if(params.elevation) then
        y = y - params.elevation*params.h*0.306; -- TODO velikost up vektoru ?? params.h*0.5 asi nebude ono 
        --print("TODO velikost up vektoru ?????")
    end
    ]]
    image.y = y;
    
    return image;
end

local function calcBtnPolygonCoord(w,h)
    local a = h*0.2;
    local wp = 0.5*(w-2*a);
    local hp = 0.5*h;
    
    return {-wp,-hp,wp,-hp,wp+a,0,wp,hp,-wp,hp,-wp-a,0};
    
end


-- creates new rounded rectangle shape button
-- params: {group=display group, top=um, left= num, cx=num, cy = num,
-- onAction=function(event), w= num, h=num, label=string, labelColor= see widgets docs, fontSize = optional font size,
-- fillColor = btn color, strokeColor = ...  }
-- either 'top' 'left' or 'cx' 'cy' has to be specified
-- w,h - optional width and height parameters, button is scaled according to size of default image if not supplied
function img:newBtn(params)
    
    assert(params.onAction, "Button has not defined action callback!");
    
    local group=params.group;
    
    assert(params.w, "Button has not defined width")
    assert(params.h, "Button has not defined height")
    
    local w = params.w;-- or def.w;
    local h = params.h;-- or def.h;
    local x,y;
    
    if(params.top and params.left) then
        x = params.left + 0.5*w;
        y= params.top + 0.5*h;
    elseif(params.cx and params.cy) then
        x = params.cx;
        y = params.cy;
    else
        error("No button position specified! Params has to contan either 'top' 'left' or 'cx' 'cy' coordinates.");
    end
    
    local widget = require( "widget" );
    local uiConst = require("ui.uiConst");
    
    --display.newImageRect(group, basePath .. dir .. "/" .. def.file, def.w, def.h);
    local btnParams =
    {
        width = w,
        height = h,
        onRelease = params.onAction,
        --defaultFile = basePath .. dir .. "/" .. name .. ".png",
        shape="polygon",--"roundedRect",
        vertices = calcBtnPolygonCoord(w,h);
        --cornerRadius = 5,
        --fillColor = { default={ 0.3, 0.3, 0.3, 1 }, over={ 0.8, 0.8, 0.8, 1 } },
        fillColor = params.fillColor or  uiConst.defBtnFillColor, --{ default={ 0.5, 0.5, 1, 0.5 }, over={ 1, 0.5, 0.5, 0.5 } },
        strokeWidth = uiConst.defBtnStrokeWidth,
        strokeColor = params.strokeColor or uiConst.defBtnStrokeColor,--{ default={ 0.5, 0.5, 1, 0.8 }, over={ 0.5, 0.5, 1, 1 } },
    }
    
    if(params.hasOver)then
        --local overImageName = name .. "_p"; -- pressed
        --btnParams.overFile = basePath .. dir .. "/" .. name .. "_p.png";
        
    end
    
    if(params.label) then
        btnParams.label = params.label;
        btnParams.font = uiConst.fontName;
        btnParams.fontSize = params.fontSize or uiConst.bigFontSize;
        btnParams.labelColor = params.labelColor or uiConst.defaultBtnLabelColor;
        btnParams.emboss = true;
    end
    
    local btn = widget.newButton(btnParams);
    
    if(group) then 
        group:insert(btn);
    end
    
    btn.x = x;
    btn.y = y;    
    local strClr = btnParams.strokeColor.default;
    
    -- change the shape params
    --print("btn: btn.numChildren: " .. btn.numChildren)
    for i= 1, btn.numChildren do
        local obj = btn[i];
        
        if(obj.blendMode and obj.text==nil) then
            --obj.fill = {type="image", filename="img/ui/actions/craks.png"}
            
            obj.stroke = {type="image", filename="img/comm/btn_stroke.png"}
        --[[
        if(params.lightness)then
            local li = params.lightness;
            obj:setStrokeColor(li*0.5, li*0.5, li*1, 1);
        else
            obj:setStrokeColor(0.5, 0.5, 1, 1);
        end
            ]]
            --obj:setStrokeColor(0.5, 0.5, 1, 1);
            obj:setStrokeColor(unpack(strClr));
            --obj:setFillColor(0.5, 0.5, 1, 0.5);
            obj.blendMode ="add";
        end
        
    end
    
    return btn;
end

-- backup
--[[ 
function img:newBtn(params)
    
    local dir = params.dir;
    assert(dir, "Cannot create button without specified image directory!" );
    
    local name = params.name;
    assert(name, "Cannot create button without specified image name!");
    
    
    assert(params.onAction, "Button has not defined action callback!");
    
    local group=params.group;
    
    assert(params.w, "Button has not defined width")
    assert(params.h, "Button has not defined height")
    
    local w = params.w;-- or def.w;
    local h = params.h;-- or def.h;
    local x,y;
    
    if(params.top and params.left) then
        x = params.left + 0.5*w;
        y= params.top + 0.5*h;
    elseif(params.cx and params.cy) then
        x = params.cx;
        y = params.cy;
    else
        error("No button position specified! Params has to contan either 'top' 'left' or 'cx' 'cy' coordinates.");
    end
    
    local widget = require( "widget" )
    
    --display.newImageRect(group, basePath .. dir .. "/" .. def.file, def.w, def.h);
    local btnParams =
    {
        width = w,
        height = h,
        defaultFile = basePath .. dir .. "/" .. name .. ".png",
        onRelease = params.onAction,
    }
    
    if(params.hasOver)then
        --local overImageName = name .. "_p"; -- pressed
        btnParams.overFile = basePath .. dir .. "/" .. name .. "_p.png";
    end
    
    if(params.label) then
        btnParams.label = params.label;
        local uiConst = require("ui.uiConst");
        btnParams.font = uiConst.fontName;
        btnParams.fontSize = params.fontSize or uiConst.bigFontSize;
        btnParams.labelColor = params.labelColor or uiConst.defaultBtnLabelColor;--{ default={ 1, 1, 1 }, over={ 0, 0, 0, 0.5 } }
        --btnParams.emboss = true;
    end
    
    local btn = widget.newButton(btnParams);
    
    if(group) then 
        group:insert(btn);
    end
    
    btn.x = x;
    btn.y = y;    
    
    
    return btn;
end
]]


return img;


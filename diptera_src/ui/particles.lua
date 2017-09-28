
local parcitles = {}

--local json = require( "json" )
local jsonIO = require("io.jsonIO");

local paramsByName = {};
local subFolder = "img/particles/"

function parcitles.newEmitter( name)
    
    local params;
    --print("adding emmiter")
    
    if(paramsByName[name]== nil)then
        local filePath =  subFolder.. name .. ".json";--= system.pathForFile( name, "img/particles/" )
        --print("filePath:" .. filePath);
        params = jsonIO:getTableFormFile(filePath);
        
        -- modify path to texture to parameters by adding subfolder
        params.textureFileName = subFolder .. params.textureFileName;
        
        paramsByName[name] = params;
    else
        params = paramsByName[name];
    end
    
    
    local emitter = display.newEmitter(params);
    
    return emitter
end
















return parcitles;


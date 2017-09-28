

local jsonIO = {}

local json = require("json");

local verboseIn = false;
local verboseOut = false;

function jsonIO:getTableFormFile(filename, directory)
    local dataTable=nil;    
    local jsonString;
    
    
    -- check whenewer levelstate file exists
    --local filePath = filename;--system.pathForFile( filename, system.DocumentsDirectory )
    local filePath;
    if(directory) then
        filePath = system.pathForFile( filename, directory);
    else
        filePath = system.pathForFile( filename, system.ResourceDirectory );
    end
     
    local file = io.open( filePath, "r" )  --check if the file already exists
    
    
    if file then -- read level states from file
        jsonString = file:read("*a");
        if(verboseIn) then print(jsonString) end;
        dataTable = json.decode(jsonString);
        io.close(file);
    else
        if(verboseIn) then  print("Warning input json file '" .. filename .. "' does not exists."); end
    end
    
    if(dataTable == nil) then
        if(verboseIn) then  print("Warning: Unsucessful json decoding! returning nill"); end;
    end
    
    return dataTable;
end

-- saves given dataTable to file in system.DocumentsDirectory usin json format
function jsonIO:saveTableToFile(filename, dataTable)
    if(dataTable == nil) then
        print("jsonIO Warning: Trying to save nil data! ");
        return;
    end
    local jsonString;
        
    -- check whenewer levelstate file exists
    local filePath = system.pathForFile( filename, system.DocumentsDirectory )
    --local filePath = system.pathForFile( filename, system.ResourceDirectory );
    --print("filepath: " .. filePath )
    local fw = io.open( filePath, "w" );  --if the file already exists it will be overwritten
    
    
    if fw then -- read level states from file
        jsonString = json.encode(dataTable, {indent = true} );
        
        if(jsonString == nil) then
            if(verboseOut) then print("jsonIO Warning: Unsucessful json encoding! "); end;
        end
        
        if(verboseOut) then print(jsonString); end;
        fw:write(jsonString);
        fw:flush();
        fw:close();
    else
        if(verboseOut) then print("jsonIO Warning: Failed to create output file '" .. tostring(filename) .. "' !"); end
    end
        
    
    return dataTable;
end

return jsonIO;
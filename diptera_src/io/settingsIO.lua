

local settingsIO = {}

local jsonIO = require("io.jsonIO");
local settingsFileName = "settings.json";
local settings= nil;

function settingsIO.getSettings()
    if(settings == nil) then
        -- try to load it from persistent storage
        settings = jsonIO:getTableFormFile(settingsFileName, system.DocumentsDirectory);
        
        if(settings == nil) then
            -- create default settings
            settings = {
                soundSettings =  {sound=true, soundVolume = 1, music=true, musicVolume=0.5};
                language = nil,
                runCount = 0,
                canShowRateMeWin  = true;
                rateMeWinShownsCount = 0;
            };
                        
        end
    end
    
    return settings;
end

function settingsIO.persistSettings()
    if(settings) then
        jsonIO:saveTableToFile(settingsFileName, settings);
    end
end




return settingsIO;




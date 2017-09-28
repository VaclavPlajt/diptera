

local worldState = {}

local jsonIO = require("io.jsonIO");
local stateFileName = "worldState.json";
local state= nil;

function worldState.getWorldState()
    if(state == nil) then
        -- try to load it from persistent storage
        state = jsonIO:getTableFormFile(stateFileName, system.DocumentsDirectory);
        
        if(state == nil) then
            state = {};
            local worldDef = require("ui.main.map.worldDef");
            local wDef = worldDef;
            
            for i=1,#wDef do
                state[wDef[i].gameName] = {cleared=false};
            end
            
            state.current = worldDef[1].gameName;
            
        end
    end
    
    
    return state;
end

function worldState.persistWorldState()
    if(state) then
        jsonIO:saveTableToFile(stateFileName, state);
    end
end

-- used by game logic to save game result
function worldState.levelCleared(name)
    
    --local wDef = require("ui.main.map.worldDef");
    local ws = worldState.getWorldState();
    
    if(ws[name] and not ws[name].cleared) then
        ws[name].cleared = true;
        worldState.persistWorldState();
    end
    
end










return worldState;



local HumanPlayerAutomation = {}

--local abs = math.abs;
--local max = math.max;

--TODO zvazti jetli tohle jeste potrebuju
function HumanPlayerAutomation:new(map)
    local gameConst = require("game.gameConst");
    local AIParams = gameConst.AIParams;
    local newHumanlayerAutomation = {};
    
    -- set meta tables so lookups will work
    setmetatable(newHumanlayerAutomation, self);
    self.__index = self;
    
    --newHumanlayerAutomation.humanPlayer = gameState.humanPlayer;
    --newHumanlayerAutomation.aiPlayer = gameState.aiPlayer;
    --newHumanlayerAutomation.gameState = gameState;
    --newHumanlayerAutomation.pathFinder = gameState.pathFinder;
    newHumanlayerAutomation.map = map;
      
       
       
    --newHumanlayerAutomation:checkClustersState();
    return newHumanlayerAutomation;
end

function HumanPlayerAutomation:restart(newMap)
    self.map = newMap;
end

function HumanPlayerAutomation:destroy()
    self.map = nil;
end

function HumanPlayerAutomation:update(timeStamp)
     --local timeStamp = system.getTimer();
     
     
     --self:updateGunsCharging(timeStamp);
     
end

--[[
function HumanPlayerAutomation:updateGunsCharging(timeStamp)
    local map =  self.map;
    
    local allGuns = map:getAllItemsOfType("Gun");
    
    if(allGuns == nil) then return; end;
    
    for id, gun in pairs(allGuns) do
        gun:updateCharging(timeStamp);
    end
    
end
]]

return HumanPlayerAutomation;




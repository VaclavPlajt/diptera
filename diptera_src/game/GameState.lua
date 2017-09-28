
-- holds all significant game state data objects
local GameState = {}

print("TODO delete gameState !!!!!!!")

function GameState:new(map, pathFinder, aiPlayer, humanPlayer)
    local newGameState = {};
    
    -- set meta tables so lookups will work
    setmetatable(newGameState, self)
    self.__index = self
    
    newGameState.isoGrid = map.isoGrid;
    newGameState.map =  map;
    newGameState.pathFinder = pathFinder;
    newGameState.aiPlayer = aiPlayer;
    newGameState.humanPlayer = humanPlayer;
    
    
    return newGameState;
end












return GameState;


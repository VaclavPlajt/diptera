
--- main live cycle game events, no game logic itself


local game = {}

local aiPlayerID = 1;
local humanPlayerID = 2;

local function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local function createGameStateObjects(game)
    
    -- initiate random numbers generator
    math.randomseed( game.mapParams.randomSeed );
    
    -- create game beginning map
    game.map = require("game.map.isoMapGen"):createNewMap(
    game.mapParams,game.startSet, game.isoGrid, game.aiPlayer,game.humanPlayer);
    
    -- copy of game constants, it have to be copy since treasures can change values in it
    game.gameConst = shallowcopy(require("game.gameConst"));
    
    
end



function game:createGame(rootGroup,contentGroup, context, name)
    self.context = context;
    
    local gameDef = require("game.gameTypesDefs")[name];
    local mapParams = gameDef.mapParams;
    self.mapParams = mapParams;
    self.contentGroup = contentGroup;
    self.rootGroup = rootGroup;
    self.gameName = name;
    
    -- init random seed
    if(not mapParams.randomSeed or mapParams.randomSeed <=0) then
        mapParams.randomSeed = os.time();
    end
    
    --print("Random seed: " .. mapParams.randomSeed);
    
    self.startSet = gameDef.startSet;
    self.instructions =  gameDef.instructions;
    
    -- 1. first create all stateles objects to keep unil the total end of the game
    
    -- create maps isoGrid
    local bounds = context.displayBounds;
    local uiConsts = context.uiConst;
    self.isoGrid = require("game.map.IsometricGrid"):new{mapSize=mapParams.size, tileW=uiConsts.mapTileWidth, cx = bounds.centerX, cy = bounds.centerY};
    
    -- create pathFinder
    self.pathFinder = require("game.map.PathFinder"):new(true);
    
    -- create players
    self.aiPlayer = require("game.Player"):new(aiPlayerID, true);
    self.humanPlayer = require("game.Player"):new(humanPlayerID, false);
    
    
    -- 2. create all game non graphics state objects
    createGameStateObjects(self); -- map, game Constants
    
    -- AI 
    self.minionController = require("game.unit.MinionController"):new(self.isoGrid, self.map, self.pathFinder , context,  self.humanPlayer); 
    self.aIPlayerBehavior = require("game.AI.AIPlayerBehavior"):new(self.map, self.pathFinder, self.aiPlayer, self.humanPlayer, self.startSet.aiPlayerStartDelay);
    self.humanPlayerAutomation = require("game.AI.HumanPlayerAutomation"):new(self.map);
    
    -- 3. create game graphics
    self.gameGraphics = require("game.gameGraphics");
    self.gameGraphics:init(contentGroup, context, self.isoGrid, self.map,self.gameConst, self.instructions);
    
    -- 4. event ralying
    self.eventRelay = require("game.eventRelay"):init(self,self.map, self.minionController, self.humanPlayer, self.gameGraphics.mapGraphics)
    
    -- 5. game logic
    self.gameLogic = require("game.GameLogic"):new(self, self.gameGraphics, self.startSet.minions)
    
    self.state = "prepared";

end


function game:getRootGroup()
    return self.rootGroup;
end

function game:getContentGroup()
    return self.contentGroup;
end


function game:startGame()
    
    -- move map to beginnig cluster
    self.gameGraphics.mapGraphics:translateToCluster(self.humanPlayer.homeCluster);
    
    -- start game logic
    self.gameLogic:start();
    
    self.gameGraphics:start();
    
    self.state = "running";
end

function game:restartGame()
    
    if(self.state == "destroyed") then 
        print("game:restartGame() Warning: game destroyed!");
        return;
    end
    
    -- dispose game graphics first
    self.gameGraphics:dispose()
    
    self.aiPlayer:clearState();
    self.humanPlayer:clearState();
    
    
    
    -- recreate all game non graphics state objects
    createGameStateObjects(self); -- map, game Constants
    
    
    -- AI 
    self.minionController:restart(self.map);
    self.aIPlayerBehavior:restart(self.map);
    self.humanPlayerAutomation:restart(self.map);
    
    
    -- restart game graphics
    self.gameGraphics:restart(self.map);
    
    -- event relay
    self.eventRelay:restart(self.map, self.gameGraphics.mapGraphics);
    
    -- game logic
    self.gameLogic:restart(self.map, self.gameGraphics)
    
    self:startGame();
    
end

function game:pause()
    --print("game:pause()");
    if(self.state ~= "running") then return; end;
    
    --print("gamePause")
    self.gameGraphics:pause();
    self.gameLogic:pause();
    transition.pause();
    self.state = "paused";
end

function game:resume()
    if(self.state ~= "paused") then return; end;
    
    --print("gameResume")
    
    transition.resume();
    self.gameLogic:resume();
    self.gameGraphics:resume();
    self.state = "running";
end

function game:destroyGame()
    
    if(self.state == "destroyed") then 
        print("game Warning: game already destroyed!");
        return;
    end
        
    
    self.minionController:destroy();
    self.aIPlayerBehavior:destroy();
    self.humanPlayerAutomation:destroy();
    
    
    -- restart game graphics
    self.gameGraphics:destroy();
    
    -- event relay
    self.eventRelay:destroy();
    
    -- game logic
    self.gameLogic:destroy();
    
    self.contentGroup = nil;
    self.rootGroup = nil;
    
    self.state = "destroyed";
end


return game;


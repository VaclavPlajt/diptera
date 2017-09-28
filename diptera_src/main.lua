--require "CiderDebugger";-- global initializations



--TODO see: http://docs.coronalabs.com/daily/api/library/native/setProperty.html handle API < 19
--native.setProperty( "androidSystemUiVisibility", "immersiveSticky" )
--print("TODO: fix bounds with immersiveSticky !!! mozna bude stacit to presunout do config.lua nebo build.settings ?? aby se to stalo vcas - NEEEfunguje")

--display.setDrawMode( "wireframe", true )

local showFps = false
display.setStatusBar( display.HiddenStatusBar )



-- create context
local context = require("context"):create();

local rootGroup = display.newGroup();

local backGroup = display.newGroup();
rootGroup:insert(backGroup);
local contentGroup = display.newGroup();
rootGroup:insert(contentGroup);

local background =  require("ui.Background"):new(backGroup,context);

local menu = true;

if(menu) then
    math.randomseed(os.time())
    --run mainMenu 
    require("ui.main.MainMenu"):new(rootGroup, contentGroup, context);
else
    -- run the tutorial map
    local game = require("game.game");
    game:createGame(rootGroup, contentGroup,context, "lvl1");-- "tutorial");
    game:startGame();
end


if(showFps) then
    local aboveGroup = display.newGroup();
    local label  =  display.newText{
        text= "x",
        parent = aboveGroup,
        x = 50,
        y = 150,--+0.5*nameTextSize,
        --width = w,
        --font= uiConst.fontName,
        fontSize = 20,
        align = "center"
    }
    label.blendMode = "add"
    
    timer.performWithDelay(500,
    function()
        label.text =  tostring(display.fps);
    end
    
    , -1);
    
end

--timer.performWithDelay(3000, function() print("ted"); transition.cancel(nil) end);



--Runtime:dispatchEvent({name="soundrequest", type="music"});

--TODO serialising of last startSet, mapParams, randomSeed
--[[
local startSet = {
    material = 50, minions = 3, wallsDensity = 0.5,-- starting set of resources, walls and treasures
    materialDepositsNum = 10, materialDepositsAmount = 50, bulletsDepositsNum = 15,
    --inactiveMinionsCount = 0,
    aiPlayerStartDelay = 10000, -- in ms
    treasures = {movementBoost=2, wallBoost=2, workBoost= 2, newMinions=7, newMaterial=2, empty = 20},
    };

local mapParams = {
    randomSeed = randomSeed,
    size=36, numOfClusters = 40, 
    playerHomePosition = "west", 
    goalPosition = "east",
    startSet = startSet
}
]]

--[[
local startSet = { -- starting set of resources, walls and treasures etc ..
    material = 50, minions = 3, wallsDensity = 0.5,
    materialDepositsNum = 2, materialDepositsAmount = 30, bulletsDepositsNum = 3,
    --inactiveMinionsCount = 0,
    treasures = {movementBoost=0, wallBoost=0, workBoost=1, newMinions=2, newMaterial=2, empty = 16},
    --treasures = {movementBoost=5, wallBoost=5, workBoost=5, newMinions=5, newMaterial=5, empty = 0},
    };


local mapParams = {
    randomSeed = randomSeed,
    size=20, numOfClusters = 9, 
    maxPowerCategory = 2,
    playerHomePosition = "west", 
    goalPosition = "east",
    startSet = startSet
}
]]





--[[
{
--  {textKey="string", startDelay= in ms, duration=in ms , endEvent = string , eventParams={{key=string, val=value}, ...}, arrowTarget=string }
    {textKey="vopravuj",-- startDelay=1000, duration=nil ,
        startEvent = "minionActionRequest", startEventParams={{key="action", val="repair"}},
        endEvent = "minionAssigmentRequest", endEventParams={{key="change", val="add"},{key="workType", val="repair"}},
        arrowTarget="minionAssigner"},
    {textKey="dokazal jsi to, jsi King", startDelay=1000, duration=2000}, --TODO upravit na startEvent
}
]]

--local bounds = context.displayBounds;
--local uiConsts = context.uiConst;




----------- TESTS and other stuff
--require("game.map.pathFinderTest"):init(mapGraphics, map);
--require("datastructures.BinaryHeapTest")

--  metaInfo test
--[[
    local names = {"actionMenu", "minionAssigner", "quickActionsMenu"};
    
    for i=1, #names do
        local w,h,top, left = uiMetaInfo:getUIPosition(names[i]);
        print(names[i] .. ": w = " .. tostring(w) .. ", h = " .. tostring(h) .. ", top = " .. tostring(top) .. ", left = " .. tostring(left));
        
        if(w and h and top and left) then
            local rect =  display.newRect(layer, left+0.5*w, top+0.5*h, w, h);
            rect:setFillColor(1, 0.5);
        end
        
    end
]]

--[[
local windowBase = require("ui.win.WindowBase"):new{ 
            context=context, layer = uiLayer, top=100, left=100,
            contentW = 500, contentH = 250, decoration = true,
            theme = theme
            };
]]

-- Minions


--require("math.spiralSearchTest"); 

--minionController:addRandomMaterialMoveRequests();

--Runtime:dispatchEvent{name="actionsAvailable", actions="emptyTileSelected"};

--local circ = display.newCircle(debugLayer, bounds.centerX, bounds.centerY, 2);
--circ:setFillColor(1,0,1);

--[[
local textSource = require("i18n.textSource"):create("cs_cz");

print(textSource:getText("example-one"))
print(textSource:getText("example-two"))
]]

-- liquid fun tests
--local layer = display.newGroup();
--require("liquidFun.liquidFun"):create(layer, context)

-- check licensing
--[[
local licensing = require( "licensing" )
licensing.init( "google" )

local function licensingListener( event )

   local verified = event.isVerified
   if not verified then
      --failed verify app from the play store, we print a message
      --print( "Pirates: Walk the Plank!!!" )
      --native.requestExit()  --assuming this is how we handle pirates
      context.analytics.logEvent("failed to verify licence");
   end
end

licensing.verify( licensingListener )
]]

--local gameGridUI = require("game.GameGridUI"):new{context=context,layer=gridLayer , left=0, tileNum=10};
--require("game.map.IsometricGridTest")
--require("game.map.mapGenerator"):int(context, mapLayer);

-- go to first scene
--[[
local sceneSwitch = context.sceneSwitch;

local worldIndex, levelIndex =  context.levelManager:getCurrentLevelIndexes()

if(not worldIndex or not levelIndex or (worldIndex==1 and levelIndex==1) ) then
    -- first start go directly to the game ...
    local mapDef = context.levelManager:getLastPlayedLevel(); --require("levels.test.completeLevelDef");

    if(mapDef== nil) then
        mapDef = context.levelManager:getFirstLevel();
    end
    sceneSwitch:switchToGameScene(mapDef);
else
    sceneSwitch:switchToMainScene();
end
]]



--local bounds = context.displayBounds;
--local myText = display.newText( "seed:" .. tostring(randomSeed), bounds.minX+80, bounds.minY+20, native.systemFont, 16 )



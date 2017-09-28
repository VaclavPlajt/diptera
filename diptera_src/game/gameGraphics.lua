
local gameGraphics = {};


local function createGraphicsStateObjects(gameGraphics, map)
    -- map graphics
    gameGraphics.mapGraphics =  require("game.map.IsoMapGraphics"):
            new(gameGraphics.context, gameGraphics.mapLayer, map);
    
end

function gameGraphics:init(rootGroup, context, isoGrid, map,gameConst, instructions)
    self.context = context;
    
    -- 1.  create all stateles objects
    
    --  create all main graphics layers
    self.rootGroup = rootGroup;
    self.backLayer = display.newGroup(); -- out-of map background layer
    rootGroup:insert(self.backLayer)
    self.mapLayer = display.newGroup(); -- game or map layer where all game viuals happens
    rootGroup:insert(self.mapLayer)
    self.inputLayer = display.newGroup(); -- layer above map Layer serves for touch events detection
    rootGroup:insert(self.inputLayer)
    self.uiLayer = display.newGroup();
    rootGroup:insert(self.uiLayer)
    --self.debugLayer = display.newGroup();
    
    -- create UI
    self.actionMenu = require("ui.actionMenu"):init(context, self.uiLayer);
    self.minionAssigner =  require("ui.minionAssigner"):init(context, self.uiLayer);
    self.materialCounter = require("ui.MaterialCounter"):new(context, self.uiLayer);
    self.quickActionsMenu = require("ui.quickActionsMenu"):init(context, self.uiLayer);
    --self.bombardtmentProgress =  require("ui.BondbardmentProgress"):new(self.uiLayer, context);
    self.uiMetaInfo = require("ui.UIMetaInfo"):new(self.actionMenu, self.minionAssigner, self.quickActionsMenu, self.materialCounter);
    self.uiRim = require("ui.uiRim"):init(self.uiLayer, context,self.uiMetaInfo);
    
    if(instructions) then
        self.instructionsUI = require("ui.Instructions"):new(self.uiLayer, context,self.uiMetaInfo, instructions);
        self.uiMetaInfo:setInstructions(self.instructionsUI);
    end
    
    self.helpLayerUI = require("ui.help.HelpLayerUI"):new(self.inputLayer, self.uiLayer, context, self.uiMetaInfo, gameConst);
    
    -- 2. create graphic state object
    createGraphicsStateObjects(self, map);
    
    -- touch/tap map events
    --(context, inputLayer, mapLayer, isoGrid)
    local limits = {
            minX = -0.5*isoGrid.width, maxX = 0.5*isoGrid.width,
            minY = -0.5*isoGrid.height, maxY = 0.5*isoGrid.height,
            minScale=context.uiConst.minScale, maxScale=context.uiConst.maxScale
            };
    
    self.playerInput = require("input.PlayerInput"):new(context, self.inputLayer, self.mapGraphics.g, isoGrid, limits);
    
    --[[
    local uiUtils = require("ui.uiUtils");
    uiUtils.newArrowPointer(self.uiLayer, context.uiConst, 300,300);
    ]]
end

function gameGraphics:start()
    if(self.instructionsUI) then
        self.instructionsUI:start();
    end
end

function gameGraphics:dispose()
    self.mapGraphics:dispose();
end


function gameGraphics:pause()
    if(self.instructionsUI) then
        self.instructionsUI:pause();
    end
end

function gameGraphics:resume()
    if(self.instructionsUI) then
        self.instructionsUI:resume();
    end
end

function gameGraphics:restart(map)
    
    
    --self.mapGraphics:dispose();
    
    
    self.mapLayer.y, self.mapLayer.x = 0, 0;
    self.mapLayer.xScale, self.mapLayer.yScale = 1, 1;
    
    -- 2. create graphic state object
    createGraphicsStateObjects(self, map);
    
    self.playerInput:setMapLayer(self.mapGraphics.g);
    
    if(self.instructionsUI) then
        self.instructionsUI:restart();
    end
    
end

function gameGraphics:hideUI(duration)
    
    local layer = self.uiLayer;
    local alpha = layer.alpha;
    
    layer.alpha = 0;
    
    timer.performWithDelay(duration, function() layer.alpha = alpha; end);
    
end


function gameGraphics:destroy()
    self.mapGraphics:dispose();
    self.mapGraphics = nil;
    
    
    self.uiRim:destroy();
    self.uiRim = nil;
    self.actionMenu:destroy();
    self.actionMenu = nil;
    self.minionAssigner:destroy();
    self.minionAssigner = nil;
    self.quickActionsMenu:destroy();
    self.quickActionsMenu = nil;
    self.materialCounter:destroy();
    self.materialCounter = nil;
    self.helpLayerUI:destroy();
    self.helpLayerUI = nil;
    if(self.instructionsUI) then
        self.instructionsUI:destroy();
        self.instructionsUI = nil;
    end
    
    self.uiMetaInfo:destroy();
    self.uiMetaInfo = nil;
    
    self.playerInput:destroy();
    self.playerInput = nil;
    
    --[[
        self.bombardtmentProgress:destroy();
    ]]
    
    -- remove all the layers
    self.backLayer:removeSelf();
    self.backLayer = nil;
    self.mapLayer:removeSelf();
    self.mapLayer = nil;
    self.inputLayer:removeSelf();
    self.inputLayer = nil;
    self.uiLayer:removeSelf();
    self.uiLayer = nil;
    
end


return gameGraphics;


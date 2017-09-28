

local GameWorld = {}

local allMinimapsAcessible = false;

function GameWorld:new(layer,backLayer, context, onPlay)
    
    
    local newGameWorld = {};
    
    setmetatable(newGameWorld, self);
    self.__index = self; 
    
    newGameWorld.layer =layer;
    newGameWorld.context = context;
    newGameWorld.onPlay = onPlay;
    newGameWorld.uiUtils = require("ui.uiUtils");
    newGameWorld.worldStateIO = require("io.worldState");
    newGameWorld.backLayer = backLayer;
    
    
    newGameWorld:init();
    
    return newGameWorld;
end



function GameWorld:destroy()
    
    self.worldStateIO.persistWorldState();
    
    if(self.g) then
        self.g:removeSelf()
        self.g = nil;
    end
    
end

function GameWorld:init()
    local context = self.context;
    local uiConst = context.uiConst;
    local bounds = context.displayBounds;
    local miniMapsMargin = 150;
    local worldState = self.worldStateIO.getWorldState();
    
    
    local g = display.newGroup();
    self.layer:insert(g);
    self.g = g;
    
    local tileW = uiConst.mapTileWidth*0.4;
    self.tileW = tileW;
    local worldDef = require("ui.main.map.worldDef");
    self.worldDef = worldDef;
    local x = 0;
    local y = bounds.centerY;
    local lastX = x;
    
    
    local miniMaps = {};
    local bridges = {};
    local gameName, lastGameName;
    
    for i=1, #worldDef do
        
        local params = worldDef[i];
        lastGameName = gameName;
        gameName =  worldDef[i].gameName;
        params.cleared = worldState[gameName].cleared;
        
        --print(gameName)
        x = x + params.mapSize*tileW*0.5;
        params.tileW = tileW;
        params.cx =x; params.cy = y;
        params.onSelection = function() self:onMiniMapSelection(params.gameName); end;
        if(i>1) then
            params.selectable = worldState[lastGameName].cleared;
        else
            params.selectable = true;
        end
        
        --print(gameName .. " cleared: ".. tostring(params.cleared));
        
        local miniMap = require("ui.main.map.MiniMap"):new(g,params,context)
        miniMaps[gameName] = miniMap;
        
        
        -- add bridges between maps
        if(i>1)then
            local lastMiniMap = miniMaps[lastGameName];
            bridges[#bridges+1] =  self:addBridge(lastX + 0.5*lastMiniMap.isoGrid.width, x-0.5*miniMap.isoGrid.width,y, 
            worldState[lastGameName].cleared, uiConst);
        end
        
        lastX = x;
        x = x + tileW*params.mapSize*0.5 + miniMapsMargin;
        
    end
    
    self.miniMaps = miniMaps;
    self.selectedMinimap = 0;
    self.w = x-miniMapsMargin;
    --display.newLine(g, 0,0, x-miniMapsMargin,0)
    
    self:addSelectionUI();
    
    -- first fun select first minipam as current
    if(not worldState.current) then
        worldState.current = worldDef[1].gameName;
    end
    
    
    
    self:switchSelection(worldState.current, false);
    
    --self:slideToMiniMap(worldState.current);
    
    --display.newLine(g, 0, 400, 550, 400);
    --local poly = display.newPolygon
    
    --[[ 
    params: {
    mapSize=number of tiles in right and up,
    tileW=tile width, tile height = tileW/2,
    cx = grid center position X coordinate,
    cx = grid center position Y coordinate,
    }
    ]]
    --[[
    local miniMapParams = {
        mapSize = 3, tileW = tileW , cx=bounds.centerX, cy = bounds.centerY, -- iso grid params
        cleared = false, -- level cleared (done)
        powerCat ="1", -- keeo power category, 1-5 or "home"
    };
    
    local miniMap = require("ui.main.map.MiniMap"):new(g,miniMapParams,context)
    ]]
    
    
    
end

function GameWorld:addBridge(x1, x2, y, active, uiConst)
    
    local g = self.g;
    local bridge = {};
    
    
    local dist = (x2-x1);
    local k = math.pi/dist;
    local h = -20;
    local f = math.sin;
    local size = 5;
    local activeSize = 15;
    y =y - size;
    --local a
    
    
    for x = 0, dist, dist/5 do
        local y = y + h*f(k*x) --x*x-x*x1-x*x2+x1*x2;
        --bridge[#bridge+1] = display.newCircle(g, x1+x, y , size);
        local img = display.newImageRect(g, "img/comm/cic.png", size, size);
        bridge[#bridge +1] = img;
        img.x = x1+x;
        img.y = y;
        
        if(active) then
            img.blendMode ="add";
            img.width = activeSize;
            img.height = activeSize;
            img:setFillColor(unpack(uiConst.defBtnStrokeColor.default))
        else
            img.alpha = 0.5;
        end
        
    end
    
    return bridge;
end

function GameWorld:addSelectionUI()
    
    
    local context = self.context;
    local uiConst = context.uiConst;
    local textSource = context.textSource;
    local margin = uiConst.defaultMargin;
    
    local btnH = uiConst.defaultBtnHeight; --uiConst.defaultBigBtnHeight;
    local btnW = 3*btnH;
    local w = btnW + 4*margin;
    local h = btnH + 4*margin;
    self.infoW = w;
    self.infoH = h;
    self.infoMargin = 3*uiConst.defaultMargin;
    
    local selectionUIGroup = display.newGroup();
    self.selectionUIGroup = selectionUIGroup;
    self.g:insert(selectionUIGroup);
    
    
    
    
    -- add arrow
    local arrow = self.uiUtils.newArrowPointer(selectionUIGroup,uiConst, 0,0);
    self.selectionArrow = arrow;
    --arrow.rotation = 45;
    -- add info group
    
    local infoGroup = display.newGroup();
    self.infoGroup = infoGroup;
    self.g:insert(infoGroup);
    
    
    --local back  = uiUtils.newUiBackRect(infoGroup, 0, 0, w, h, self.context, 10, true);
    --back:addEventListener("touch", function() return true end);
    --back:addEventListener("tap", function() return true end);
    
    
    
    local playBtn = context.img:newBtn
    {
        group=infoGroup, cx=0, cy = 0,
        w= btnW, h=btnH,
        label=textSource:getText("mm.newGame"),
        --labelColor= see widgets docs,
        fontSize = uiConst.bigFontSize,
        onAction=function() self:onPlayBtn(); end,
        fillColor = uiConst.darkerBtnFillColor,
        strokeColor = uiConst.darkerBtnStrokeColor,
    }
end

function GameWorld:switchSelection(gameName, playSound)
    
    --print("selected: " .. gameName);
    if(self.selectedMinimap == gameName) then
        return;
    end
    
    local lastSelected = self.selectedMinimap;
    if(lastSelected and  self.miniMaps[lastSelected]) then
        self.miniMaps[lastSelected]:cancelSelection();
    end
    
    self.selectedMinimap = gameName;
    --local worldState = self.worldStateIO.getWorldState();
    --local cleared = worldState[gameName].cleared;
    
    
    -- get minimap
    local miniMap = self.miniMaps[gameName];
    local isoGrid = miniMap.isoGrid;
    local cx, cy = miniMap.g.x, miniMap.g.y;
    
    -- position arrow
    local dist = 20;
    local travelDist = 350;
    --local x,y = cx+isoGrid.centerX,cy+isoGrid.centerY;
    local x,y = cx+isoGrid.centerX-0.25*isoGrid.width-self.infoMargin,cy+isoGrid.centerY-0.25*isoGrid.height-self.infoMargin;
    --local x,y = cx,cy-0.5*isoGrid.height;
    --local x,y = cx,cy-0.5*isoGrid.height-self.infoMargin*2;
    --local dirX,dirY = 0, -1; -- down direction
    
    --local dirX,dirY = -(x-isoGrid.centerX), -(y-isoGrid.centerY); --from center to edge center direction vector
    
    local dirX,dirY = (isoGrid.centerX-isoGrid.width*0.25)-(isoGrid.centerX+isoGrid.width*0.25), (isoGrid.centerY-isoGrid.height*0.25)-(isoGrid.centerY+isoGrid.height*0.25);
    
    --local dirX,dirY = 0.5*isoGrid.width, -0.5*isoGrid.height; -- minimap edge direction vector
    --dirX,dirY = dirY, -dirX; -- vector perperdicular to minimap edge
    
    local length = math.sqrt(dirX*dirX+dirY*dirY);
    dirX,dirY = dirX/length,dirY/length; -- normalization
    local x2,y2 = x+(travelDist+dist)*dirX, y+(travelDist+dist)*dirY;
    
    local arrow = self.selectionArrow;
    --display.newLine(self.g, x, y, x2, y2);
    
    if(arrow.rotation ==0) then
        local aDirX, adirY = -1, 0; -- axis direction vector
        local dot = dirX*aDirX + dirY*adirY; -- dot product of two normalized vectors
        local angle =  math.deg(math.acos(dot));
        --print("angle:" .. angle);
        arrow.rotation = angle;
    end
    
    arrow.x = x2;
    arrow.y = y2;
    
    local x3,y3 = x+dist*dirX, y+dist*dirY;
    
    transition.cancel(arrow)
    transition.to(arrow, {x=x3, y=y3, delay= 150, time = 650, transition = easing.outCubic })
    
    local arrowAlpha = arrow.alpha;
    arrow.alpha = 0;
    transition.to(arrow,{alpha=arrowAlpha, time = 600, onCancel = 
        function()
            arrow.alpha = arrowAlpha;
        end
    });
    
    --display.newCircle(self.g, isoGrid.centerX-0.5*isoGrid.width, isoGrid.centerY-0.5*isoGrid.height, 10);
    
    -- move info UI
    self.infoGroup.x = cx;--+self.infoH+self.infoMargin;
    self.infoGroup.y = cy+isoGrid.maxY+self.infoH*0.5+self.infoMargin;
    
    -- paticle effect path
    if(self.pathTransition) then
        self.uiUtils.cancelTransitionList(self.pathTransition);
        self.pathTransition =nil;
    end
    
    if(self.selectionEmitter) then
        self.selectionEmitter:removeSelf();
        self.selectionEmitter = nil;
    end
    
    
    
    local emitter;
    --if(cleared) then
    --if(true) then
    local path = {cx-0.5*isoGrid.width, cy, cx, cy-0.5*isoGrid.height, cx+0.5*isoGrid.width,cy, cx, cy+0.5*isoGrid.height};
    emitter = require("ui.particles").newEmitter("heal_area") --display.newCircle(self.g, cx, cy, 15);
    self.pathTransition = self.uiUtils.followPathTransition(emitter, path, 500,  -1, easing.inOutSine);
    --[[
    else
        emitter = require("ui.particles").newEmitter("enemy_area");
        emitter.x, emitter.y = cx, cy;
        local size = 0.5*math.min(isoGrid.width,isoGrid.height)
        emitter.sourcePositionVariancex = size;
        emitter.sourcePositionVariancey = size;
        local area = size*size;--isoGrid.width*isoGrid.height;
        emitter.emissionRateInParticlesPerSeconds = area * 0.001;
        print("emissionRateInParticlesPerSeconds: " .. emitter.emissionRateInParticlesPerSeconds);
        --emitter.alpha = 0.75
    end
    ]]
    
    emitter.duration = -1;
    self.g:insert(emitter);
    self.selectionEmitter = emitter;
    
    
    
    if( playSound) then
        -- play sound
        --Runtime:dispatchEvent({name="soundrequest", type="playnammed", soundName="map_selected"});--, x=x, y=y});  )
        Runtime:dispatchEvent({name="soundrequest", type="button"}); -- play button sound 
    end
    
    --local backStripNum = math.ceil((isoGrid.size-1)/2)
    --self.backAnim:selectStripe(backStripNum);
    self:slideToMiniMap(gameName);
    
    
end


function GameWorld:onMiniMapSelection(gameName)
    
    if(self:isMiniMapAcessible(gameName)) then
        self:switchSelection(gameName, true);
    else
        --print("TODo minimap not acessible, show some animation.")
        self:onWrongSelection(gameName)
    end
    
end


function GameWorld:onWrongSelection(gameName)
    -- get minimap
    local miniMap = self.miniMaps[gameName];
    --local isoGrid = miniMap.isoGrid;
    local cx, cy = miniMap.g.x, miniMap.g.y;
    
    if(not self.wrongSelMarker) then
        self.wrongSelMarker = display.newImageRect(self.g, "img/comm/wrongSelection.png", 128, 64)
        self.wrongSelMarker.blengMode = "multiply"
    end
    
    local marker = self.wrongSelMarker;
    
    marker.alpha = 0.75;
    marker.x = cx;
    marker.y = cy;
       
    transition.cancel(marker);
        
    marker.fadeTransition =  transition.to(marker,
    {alpha=0, delay= 50, time=250,
    --onComplete = function() marker.fadeTransition = nil; end
    });
    
    -- play sound
    Runtime:dispatchEvent({name="soundrequest", type="playnammed", soundName="wrong"});--, x=x, y=y});      
end

function GameWorld:isMiniMapAcessible(gameName)
    if(allMinimapsAcessible) then
        return true;
    else
        local miniMap = self.miniMaps[gameName];
        return miniMap.isAcessible;
    end
    
    --return true;
end


-- centers minimap to screen
function GameWorld:slideToMiniMap(gameName)
    
    -- get minimap
    local miniMap = self.miniMaps[gameName];
    --local isoGrid = miniMap.isoGrid;
    local cx = miniMap.g.x;
    local bounds = self.context.displayBounds;
    --print("minimap cx:" .. cx)
    cx = cx-bounds.minX-0.5*bounds.width;
    transition.to(self.layer, {x=-cx, time=450});
end

function GameWorld:onPlayBtn()
    
    if(self.onPlay) then
        -- remember last played minimap
        local worldState  = self.worldStateIO.getWorldState()
        worldState.current = self.selectedMinimap;
        
        self.onPlay(self.selectedMinimap);--self.worldDef[self.selectedMinimap].gameName);
        
        -- log event to analytics
        self.context:analyticslogEvent("GameWorld-playMap", {mapName=self.selectedMinimap});
        
    end
end

return GameWorld;


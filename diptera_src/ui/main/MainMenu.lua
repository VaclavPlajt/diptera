local MainMenu = {}

local crystalW = 226;
local crystalH = 512;

local maskExpansionTime = 350;
local popInTime = 550;

function MainMenu:new(rootGroup,contentGroup, context, returningFromGame)
    
    local newMainMenu = {};
    
    setmetatable(newMainMenu, self);
    self.__index = self; 
    
    
    newMainMenu.rootGroup =rootGroup;
    newMainMenu.contentGroup = contentGroup;
    newMainMenu.context = context;
    newMainMenu.uiConst = context.uiConst;
    newMainMenu.bounds = context.displayBounds;
    
    if(context.settings.language == nil) then
        require("ui.main.LanguageSelector"):new(rootGroup, context,
        function(langCode)
            --print("TODO actually set the language!!")
            context:setLanguage(langCode);
            newMainMenu:init();
        end);
    else
        newMainMenu:init(returningFromGame);
    end
    
    -- log event to analytics
    context:analyticslogEvent("MainMenu");
    
    return newMainMenu;
    
end


function MainMenu:init(returningFromGame)
    
    -- add layers
    self.g = display.newGroup(); -- main group
    self.contentGroup:insert(self.g);
    
    self.backLayer =  display.newGroup();
    self.g:insert(self.backLayer);
    
    self.gameMapLayer =  display.newGroup();
    self.g:insert(self.gameMapLayer);
    
    self.aboveGameMapLayer =  display.newGroup();
    self.g:insert(self.aboveGameMapLayer);
    
    self.uiLayer =  display.newGroup();
    self.g:insert(self.uiLayer);
    
    self.aboveUi =  display.newGroup();
    self.g:insert(self.aboveUi);
    
    
    
    local showUI =  true; -- turns ui on and off, useful for generating promo images
    
    
    if(showUI)then
        -- add game world map
        self:addGameWorld();
        
        
        -- add menu items
        self:addMenuItems();
        
        -- add 
        self:addSoundOptionsBtns()
    end
    
    -- add efects and animations
    self.backAnim = require("ui.main.BackAnim"):new(self.backLayer,self.context);
    
    --self.aboveGameMapLayer
    self:frontEffects();
    
    -- add touch/swipe input
    -- touch/tap map events
    
    if(showUI)then
        local sideMargin = self.bounds.width*0.5;
        local bounds = self.bounds;
        local limits = {
            minX = -(self.gameWorld.w-bounds.width+math.abs(bounds.minX)+sideMargin), maxX = bounds.minX+sideMargin,--sideMargin,
            minY = 0, maxY=0,
            minScale=1,1
        };
        
        self.playerInput = require("input.PlayerInput"):new(self.context, self.backLayer, self.gameMapLayer, nil, limits);
    end
    
    --display.newCircle(self.gameMapLayer, self.gameWorld.w, self.bounds.centerY, 5);
    --display.newCircle(self.gameMapLayer, 0, self.bounds.centerY, 5);
           
    self:startExpansionEffect()
    self:popInContent();
    
    -- decide whenewer show 'please rate me window...'
    
    local settings = self.context.settings;
    local rateMeWinShownsCount = settings.rateMeWinShownsCount;
    if(rateMeWinShownsCount == nil) then
        rateMeWinShownsCount = 0;
        settings.rateMeWinShownsCount = 0;
    elseif (rateMeWinShownsCount > 5) then
        settings.canShowRateMeWin = false;
    end
    -- save settings to persistent memory
    self.context.settingsIO:persistSettings();
    
    if(returningFromGame and settings.runCount > 1  and settings.canShowRateMeWin) then
        require("ui.win.RateMePane"):new(self.uiLayer, self.context);
    end
    
    
end

function MainMenu:destroy()
    --print("MainMenu:destroy()")
    if(self.backAnim) then
        self.backAnim:destroy();
        self.backAnim = nil;
    end
    
    if(self.gameWorld) then
        self.gameWorld:destroy();
        self.gameWorld = nil;
    end
    
    if(self.g) then
        self.g:removeSelf();
        self.g = nil;
        transition.cancel();
    end
end

function MainMenu:popInContent()
    
    
    --self.backLayer.alpha = 0;
    --transition.to(self.backLayer, {alpha=1, time=popInTime, transition = easing.inOutSine});
    self.gameMapLayer.alpha = 0;
    transition.to(self.gameMapLayer, {alpha =1, time=popInTime, delay=maskExpansionTime, transition = easing.inOutSine});
    self.uiLayer.alpha = 0;
    transition.to(self.uiLayer, {alpha=1, time=popInTime, delay = maskExpansionTime, transition = easing.inOutSine});
    
end


function MainMenu:startExpansionEffect()
    local bounds = self.bounds;
    local startMask = graphics.newMask("img/comm/start_mask.png");
    local maskSize = 128;
    local overExpansionRatio = 1.6;
    local maxScaleX = overExpansionRatio*bounds.width / maskSize;
    local maxScaleY = maxScaleX--overExpansionRatio*bounds.height / maskSize;
    local minSize = 100;
    local minScale = minSize/maskSize;
    
    self.rootGroup:setMask(startMask);
    self.rootGroup.maskX = bounds.centerX;
    self.rootGroup.maskY = bounds.centerY;
    self.rootGroup.maskScaleX = minScale;
    self.rootGroup.maskScaleY = minScale;
    
    transition.to(self.rootGroup, {maskScaleX=maxScaleX, maskScaleY=maxScaleY, time=maskExpansionTime, onComplete = 
        function()
            self.rootGroup:setMask(nil);
        end
    })
end

function MainMenu:addBackground()
    
    local bounds = self.bounds;
    self.backMargin = self.bounds.height*0.05;
    local w =  bounds.width-2*self.backMargin;
    local h =  bounds.height-2*self.backMargin;
    
    local textureSize = 512;
    display.setDefault( "textureWrapX", "repeat" )
    display.setDefault( "textureWrapY", "repeat" )
    
    --[[
    local back = display.newPolygon(self.backLayer, bounds.centerX, bounds.centerY, 
    {isoGrid.minX, isoGrid.centerY, isoGrid.centerX, isoGrid.minY, isoGrid.maxX, isoGrid.centerY, isoGrid.centerX, isoGrid.maxY}
    );
    ]]
    
    local back =  display.newRect(self.backLayer, bounds.centerX, bounds.centerY,w,h);
    
    back.fill = {type="image", filename= "img/back.png"}
    --back:setFillColor(0.5,0.5)
    --local s = textureSize/isoGrid.width; print("W: " .. isoGrid.width .. ", S:" .. s .. "repeated:" .. 1/s .." times")
    
    back.fill.scaleX = textureSize/w;
    back.fill.scaleY = textureSize/h;
    
    back.blendMode = "add";
    back.alpha = self.uiConst.mapBackgroundAlpha;-- 0.4;
    
    display.setDefault( "textureWrapX", "clampToEdge" )
    display.setDefault( "textureWrapY", "clampToEdge" )
    
    -- add crystal
    
    local img = display.newImageRect(self.backLayer, "img/mm/crystal.png", crystalW, crystalH);
    img.x = bounds.minX + 0.5*crystalW;
    img.y = bounds.maxY - 0.5*crystalH;
    
end



--[[
function MainMenu:addGameLogo()
    local layer = self.uiLayer;
    local bounds = self.bounds;
    local uiConst = self.uiConst;
    local cy = bounds.minY + bounds.height*0.3*0.5;
    local cx = bounds.centerX;
    
    
    local label  = display.newText{ -- game name
        text= self.context.textSource:getText("mm.gameName"),
        parent = layer,
        x = cx,--left+margin,--cx,
        y = cy,
        --width = labelW,
        height = 0,
        font= uiConst.fontName,
        fontSize = uiConst.hugeFontSize,
        align = "center",
    }
    
    label:setFillColor(unpack(uiConst.highlightedFontColor));
    
    
end
]]

function MainMenu:addSoundOptionsBtns()
    local g = display.newGroup();
    self.uiLayer:insert(g);
    
    local bounds = self.bounds;
    local uiConst = self.uiConst;
    local margin = uiConst.defaultMargin;
    
    local soundSettings = self.context.settings.soundSettings;
    
    local h = 64;
    
    local x = bounds.minX;
    local y = bounds.maxY - 0.5*h - margin;
    
    local w = 36;
    local disColor = {0.75,0.1,0.1}; --uiConst.defBtnFillColor.over
    local m = math.max(w,h);
    local cx = x + 0.5*m + margin;
    
    local musicIcon = display.newImageRect(g,"img/ui/music.png", w, h);
    musicIcon.x = cx;
    musicIcon.y = y;
    musicIcon:setFillColor(unpack(uiConst.defBtnFillColor.default))
    musicIcon.blendMode = "add";
    
    local musicDisabled = display.newImageRect(g,"img/ui/disabled.png", h, h);
    musicDisabled.x = cx;
    musicDisabled.y = y;
    musicDisabled:setFillColor(unpack(disColor))
    musicDisabled.blendMode = "add";
    if(soundSettings.music) then musicDisabled.isVisible = false; end;
    self.musicDisabledIcon = musicDisabled;
    
    local musicBct = display.newRect(g, cx, y, m , m);
    musicBct:addEventListener("tap", function() return self:onMusicOnOff() end);
    musicBct.isVisible = false;
    musicBct.isHitTestable = true;
    
    x= x+ math.max(w,h) + margin;
    
    w = 57;
    m= math.max(w,h);
    cx = x + 0.5*m + margin;
    
    local soundIcon = display.newImageRect(g,"img/ui/sound.png", w, h);
    soundIcon.x = cx;
    soundIcon.y = y;
    soundIcon:setFillColor(unpack(uiConst.defBtnFillColor.default))
    soundIcon.blendMode = "add";
    
    local soundDisabled = display.newImageRect(g,"img/ui/disabled.png", h, h);
    soundDisabled.x = cx;
    soundDisabled.y = y;
    soundDisabled:setFillColor(unpack(disColor))
    soundDisabled.blendMode = "add";
    if(soundSettings.sound) then soundDisabled.isVisible = false; end;
    self.soundDisabledIcon = soundDisabled;
    
    local soundBtn = display.newRect(g, cx, y, m , m);
    soundBtn:addEventListener("tap", function() return self:onSoundOnOff() end);
    soundBtn.isVisible = false;
    soundBtn.isHitTestable = true;
    
end

function MainMenu:onMusicOnOff()
    
    local soundSettings = self.context.settings.soundSettings --{sound=true, soundVolume = 0.5, music=true, musicVolume=0.3};
    local soundManager = self.context.soundManager;
    
    if(soundSettings.music)then
        -- turn music off
        soundSettings.music = false;
        soundManager:stopMusic();
        self.musicDisabledIcon.isVisible = true;
    else
        -- turn music on
        soundSettings.music = true;
        soundManager:playMusic();
        self.musicDisabledIcon.isVisible = false;
    end
    
    Runtime:dispatchEvent({name="soundrequest", type="button"}); -- play button sound
    
    -- save settings to persistent memory
    self.context.settingsIO:persistSettings();
    
    
    return true;
end

function MainMenu:onSoundOnOff()
    local soundSettings = self.context.settings.soundSettings --{sound=true, soundVolume = 0.5, music=true, musicVolume=0.3};
    --local soundManager = self.context.soundManager;
    
    if(soundSettings.sound)then
        -- turn music off
        soundSettings.sound = false;
        --soundManager:stopMusic();
        self.soundDisabledIcon.isVisible = true;
    else
        -- turn music on
        soundSettings.sound = true;
        --soundManager:playMusic();
        self.soundDisabledIcon.isVisible = false;
    end
    
    Runtime:dispatchEvent({name="soundrequest", type="button"}); -- play button sound
    
    -- save settings to persistent memory
    self.context.settingsIO:persistSettings();
    
    
    return true;
end


function MainMenu:addMenuItems()
    
    
    local g = self.uiLayer;
    local bounds = self.bounds;
    local uiConst = self.uiConst;
    local margin = uiConst.defaultMargin;
    local textSource = self.context.textSource;
    local btnH = uiConst.defaultSmallBtnHeight; --uiConst.defaultBigBtnHeight;
    local btnW = 4*btnH;
    local backH = btnH + 2*margin;
    --local backW = bounds.width;
    local cy = bounds.maxY - backH*0.5;  --bounds.minY + bounds.height*0.4;
    --local cx = bounds.centerX;
    local w = bounds.width;-- - 2*self.backMargin;
    
    
    
    local itemTexts = {"rateme.mmButtonText", "mm.about"}; --"mm.help" 
    local itemActions = {"onRateMeBtn", "onAboutBtn"};
    
    local img = self.context.img;
    
    
    --add backgound
    --local uiUtils = require("ui.uiUtils");
    --local back  = uiUtils.newUiBackRect(g, cx, cy, backW, backH, self.context, 0, false);
    --back.alpha = 0.4;
    
    -- add top rim
    --local backTop = bounds.maxY - backH;
    --local rim = display.newLine(g, bounds.minX, backTop, bounds.maxX, backTop);
    --rim.strokeWidth = 16;
    --rim.stroke = {type="image", filename="img/comm/rim_stroke.png"}
    --rim.blendMode ="multiply";
    
    --local btnMargin = (w - #itemTexts*btnW)/;
    local dx = btnW+2*margin--((w - #itemTexts*btnW) / (#itemTexts+1)) + btnW;
    local btnX = bounds.maxX - #itemTexts*dx +0.5*btnW -margin  --bounds.minX + margin + dx-0.5*btnW;
    
    for i=1, #itemTexts do
        -- creates new rounded rectangle shape button
        -- params: {group=display group, top=um, left= num, cx=num, cy = num,
        -- onAction=function(event), w= num, h=num, label=string, labelColor= see widgets docs, fontSize = optional font size}
        -- either 'top' 'left' or 'cx' 'cy' has to be specified
        -- w,h - optional width and height parameters, button is scaled according to size of default image if not supplied
        img:newBtn
        {
            group=g, cx=btnX, cy = cy,
            w= btnW, h=btnH,
            label=textSource:getText(itemTexts[i]),
            --labelColor= see widgets docs,
            fontSize = uiConst.normalFontSize, lightness = 0.1,
            onAction=function() self:onMenuItemAction(itemActions[i]) end
        }
        
        btnX = btnX + dx;
        
    end
    
end

function MainMenu:onMenuItemAction(actionName)
    
    Runtime:dispatchEvent({name="soundrequest", type="button"}); -- play button sound
    
    if(actionName == "onAboutBtn") then
        require("ui.main.About"):new(self.aboveUi, self.context);
    elseif (actionName == "onRateMeBtn") then
        require("ui.win.RateMePane"):new(self.uiLayer, self.context);
    else
        print("Unimplemented main menu item action: " .. tostring(actionName))
    end
    
    -- log event to analytics
    self.context:analyticslogEvent(actionName);
    
end



function MainMenu:addGameWorld()
    
    self.gameWorld = require("ui.main.map.GameWorld"):new(self.gameMapLayer, self.backLayer, self.context, 
    function(mapName) self:onPlay(mapName); end
    );
    
end


function MainMenu:onPlay(mapName)
    --print("MainMenu:onPlay(), mapIndex: " .. tostring(mapName));
    
    Runtime:dispatchEvent({name="soundrequest", type="button"}); -- play button sound
    
    -- remove main menu UI
    self:destroy();
    
    -- start new game ...
    local game = require("game.game");
    game:createGame(self.rootGroup, self.contentGroup,self.context, mapName);
    game:startGame();
end


function MainMenu:frontEffects()
    --print("TODO MainMenu:frontEffects()");
    
    --ewMainMenu.context = context;
    local uiConst = self.uiConst;
    local bounds = self.bounds;
    
    
    -- add front rectangle
    local rect = display.newRect(self.aboveGameMapLayer, bounds.centerX, bounds.centerY, bounds.width, bounds.height);
    rect.fill = {
        type = "gradient",
        color1 = { 0.5,0.3,0.3,1 },
        color2 = { 0.1,0.1,0.5,1 },
        direction = "down"
    }
    
    --rect.fill.rotation = 45;
    
    --print(tostring(rect.fill));
    --transition.to(rect.fill.color1)
    
    rect.alpha = 0.2;
    rect.blendMode = "add";
    
    
    -- add vingnetation 
    --[[
    local rectVig = display.newRect(self.aboveGameMapLayer, bounds.centerX, bounds.centerY, bounds.width, bounds.height);
    
    --rectVig.alpha = 0.5;
    rectVig:setFillColor(1, 0.0);
    
    rectVig.fill.effect = "filter.vignette";
    rectVig.fill.effect.radius = 0.1;
    ]]
end

return MainMenu;



local context =  {}


function context:create()
    
    -- debug options
    self.debug = false;
    
    -- get device info
    self.device = require("device");
    
    -- initiate Flurry analytics
    self:startAnalytics(self.debug); 
    
    
    -- image module initialization
    self.img =require("img.img"); 
    
    self:createDisplayBounds();
    
    -- settings
    self.settingsIO = require("io.settingsIO");
    self.settings = self.settingsIO.getSettings();
    
    -- increase run count
    if(self.settings.runCount) then 
        self.settings.runCount = self.settings.runCount + 1;
    else
        self.settings.runCount = 1;
    end
        
    -- add canShowRateMeWin if needed
    if(self.settings.canShowRateMeWin== nil) then
        self.settings.canShowRateMeWin = true;
    end
    
    -- save settings to persistent memory
    self.settingsIO:persistSettings();
    
    -- sounds
    local soundSettings = self.settings.soundSettings --{sound=true, soundVolume = 0.5, music=true, musicVolume=0.3};
    self.soundManager = require("sound.soundManager"):create(soundSettings, self.displayBounds);
    
    self.uiConst = require("ui.uiConst");
    
    --self.textSource =  require("i18n.textSource"):create("en_us")
    self.textSource =  require("i18n.textSource"):create(self.settings.language)
    
    
    if(self.settings.language == nil) then
        self:determineLanguage();
    end
    
    
    self.systemEventsHandler = require("systemEventsHandler"):create(self);
    
    -- not tested !!
    self:checkGooglePlayLinence();
    
    return self;
end

function context:createDisplayBounds()
    -- calc display bounds
    local displayBounds = {
        minX=display.screenOriginX ,
        minY= display.screenOriginY,
        maxX=display.viewableContentWidth + math.abs(display.screenOriginX),--display.contentWidth+math.abs(display.screenOriginX),
        maxY=display.viewableContentHeight + math.abs(display.screenOriginY)--display.contentHeight + math.abs(display.screenOriginY)
    };
    
    displayBounds.width = displayBounds.maxX - displayBounds.minX;
    displayBounds.height = displayBounds.maxY - displayBounds.minY;
    displayBounds.centerX = displayBounds.minX + displayBounds.width*0.5;
    displayBounds.centerY = displayBounds.minY + displayBounds.height*0.5;
    
    self.displayBounds = displayBounds;
end

function context:determineLanguage()
    
    
    local prefLanguage = system.getPreference( "locale", "language");
    --system.getPreference( "ui", "language" ))
    
    if(type(prefLanguage) ~= "string") then
        return;
    end
    
    prefLanguage = string.lower(prefLanguage);
    --prefLanguage = " čeština (česká republika)"
    --print("pref lang: " .. prefLanguage)
    local langCode =  nil
    local find  = string.find;
    
    if( find(prefLanguage,"en",1,true) or find(prefLanguage,"english",1,true))then
        langCode = "en_us";
    elseif(find(prefLanguage,"cz",1,true) or find(prefLanguage, "cs",1,true) or 
        find(prefLanguage,"czech",1,true) or find(prefLanguage,"čeština",1,true))then
        langCode = "cs_cz";
    end
    
    if(langCode) then
        print("detected language: " .. langCode )
        self:setLanguage(langCode);
        --else
        --    print("Language not recognized automatically.")
    end
    
end


function context:setLanguage(langCode)
    --print("language set to:".. langCode);
    self.settings.language = langCode;
    
    self.textSource:setLanguage(langCode);
    
    -- save settings to persistent memory
    self.settingsIO:persistSettings();
end


function context:startAnalytics(devel)
    local appKey = nil;
    local device = self.device;
    
    -- true only in the Corona Simulator not for example in  Xcode iOS Simulator or  Android emulator or and Windows Phone emulator
    if(device.isSimulator) then
        --print("no analytics in simulator ...")
        return;
    end
    
    -- get platform name name
    ---local platformName = system.getInfo( "platformName" );
    
    
    if( device.isApple) then
        if(devel) then
            appKey = nil;
        else
            appKey = "supply-key-of-your-own"; -- Diptera iOS key
        end
        
    elseif(device.isGoogle) then
        if(devel) then
            appKey = "supply-key-of-your-own"; --  Android development project key
        else
            appKey = "supply-key-of-your-own"; -- Diptera android key
        end
    end
    
    
    if(appKey) then
        local analytics = require "analytics";
        self.analytics = analytics;
        
        analytics.init( appKey );
    end
end

function context:analyticslogEvent(eventName, params)
    if(not self.analytics) then
        return; -- analytics off
    end
    
    self.analytics.logEvent( eventName, params );
end


function context:checkGooglePlayLinence()
    -- check licensing
    local device = require("device");
    if(device.isSimulator) then
        return;
    end
    
    if(device.isGoogle) then 
        local licensing = require( "licensing" )
        licensing.init( "google" )
        
        local function licensingListener( event )
            
            local verified = event.isVerified
            if not verified then
                --failed verify app from the play store, we print a message
                --print( "Pirates: Walk the Plank!!!" )
                --native.requestExit()  --assuming this is how we handle pirates
                if self.analytics then
                    self.analytics.logEvent("failed to verify licence");
                end
            end
        end
        
        licensing.verify( licensingListener )
    end
end

return context;


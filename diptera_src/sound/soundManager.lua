
local soundManager = {}

-- known sounds
soundManager.soundsFile = "sounds.json";
soundManager.streams = {};

-- paths
soundManager.soundsPath = "sound/";

-- music
soundManager.numOfReservedChanels = 1;
soundManager.musicReservedChanel = 1;
soundManager.musicFile = "music.json";
soundManager.musicPaused = false;


--local rnd = math.random;

-- TODO presunout do jednoho skriptu !!
local function getTableFormFile(filename)
    local dataTable=nil;    
    local jsonString;
    local json = require("json");
    
    -- check whenewer levelstate file exists
    --local filePath = filename;--system.pathForFile( filename, system.DocumentsDirectory )
    local filePath = system.pathForFile( filename, system.ResourceDirectory );
    local file = io.open( filePath, "r" )  --check if the file already exists
    
    
    if file then -- read level states from file
        jsonString = file:read("*a");
        dataTable = json.decode(jsonString);
        io.close(file);
    end
    
    
    return dataTable;
end

--TODO pre load as recomended at http://docs.coronalabs.com/guide/media/audioSystem/index.html
function soundManager:create(soundSettings, displayBounds)
    -- load all sounds to table 
    
    self.settings = soundSettings;
    self.bounds = displayBounds;
    
    
    self:loadSounds();
    --self:play("success");
    
    -- reserve channels
    audio.reserveChannels(soundManager.numOfReservedChanels);
    
    -- listen to sound requests
    self.soundRequestListener = function(event) self:onSoundRequest(event) end;
    Runtime:addEventListener("soundrequest", self.soundRequestListener);
    
    -- pop in init
    self.lastPopInTime = system.getTimer();
    
    -- schedule automatic music playback
    
    timer.performWithDelay(250, 
    function()
        --self:loadSounds();
        self:playMusic();
    end);
    
    return self;
end


function soundManager:loadSounds()
    local extension= ".mp3";
    local path = self.soundsPath;
    local soundData = getTableFormFile(path .. self.soundsFile);
    local sounds = {};
    local soundPath;
    
    if(soundData) then
        
        local handle;
        for name,def in pairs(soundData) do
            soundPath = path .. def.file .. extension;
            
            handle = audio.loadSound(soundPath);
            
            if(handle) then
                local s = {handle = handle, channels=0};
                
                if(def.volume) then
                    s.volume = def.volume;
                end
                
                if(def.multichannel) then
                    s.multichannel = def.multichannel;
                end
                
                sounds[name] = s;
            else
                print("Warning: Sound file " .. soundPath .. " not loaded!!")
            end
        end
        
    else
        print("Warning: no sound data found!");
    end
    
    self.sounds = sounds;
end

function soundManager:playMusic()
    
    if(self.settings.music)then
        local name = "music";
        local sound = self.sounds[name];
        
        
        if(sound) then
            
            if(sound.channels == 0) then
                local channel = soundManager.musicReservedChanel
                audio.play(sound.handle, {
                    channel=channel,
                    loops = -1,
                    onComplete = function() sound.channels=sound.channels-1; end
                });
                sound.lastChannel = channel;
                sound.channels = sound.channels +1;
                -- set volume
                if(sound.volume) then
                    audio.setVolume(self.settings.musicVolume*sound.volume, {channel=channel});
                else
                    audio.setVolume(self.settings.musicVolume, {channel=channel});
                end
                
                --print("music playing on channel: " .. tostring(channel))
            else
                print("Sound:" .. name  .. " already playing." .. "channels: " .. sound.channels)
            end
            
            
        else
            print("Sound named : " .. name .. " cannot be played");
        end
    else
        --print("sound is off")
    end
    
end


function soundManager:stopMusic()
        
    audio.stop(soundManager.musicReservedChanel);
    --TODO unload music from memory ?
end

function soundManager:pauseMusic()
    
    if(self.settings.music)then
        audio.pause(soundManager.musicReservedChanel);
        self.musicPaused = true;
    end
    
    
end

function soundManager:resumeMusic()
    
    if(self.settings.music and self.musicPaused)then
        audio.resume(soundManager.musicReservedChanel);
        self.musicPaused = false;
    end
    
end

function soundManager:isOnScreen(x,y)
    
    -- is within display bounds ?
    local bounds = self.bounds;
    
    if(x >= bounds.minX and x<=bounds.maxX 
        and y >= bounds.minY and y<=bounds.maxY )then
        return true;
    else
        return false;
    end
end

-- plays a sound with given name if is not currently playing 
function soundManager:play(name)
    
    if(self.settings.sound)then
        
        local sound = self.sounds[name];
        
        
        if(sound) then
            
            if(sound.channels == 0 or sound.multichannel) then
                
                
                local channel = audio.play(sound.handle, {onComplete = function() sound.channels=sound.channels-1; end});
                sound.lastChannel = channel;
                sound.channels = sound.channels +1;
                -- set volume
                if(sound.volume) then
                    audio.setVolume(self.settings.soundVolume*sound.volume, {channel=channel});
                else
                    audio.setVolume(self.settings.soundVolume, {channel=channel});
                end
                
                --print(tostring(name) .. " playing on channel: " .. tostring(channel));
                
            else
                --print("Sound:" .. name  .. " already playing." .. "channels: " .. sound.channels)
            end
        else
            print("Sound named : " .. name .. " cannot be played");
        end
    else
        --print("sound is off")
    end
    
end

function soundManager:onSoundRequest(event)
    local type = event.type;
    
    if(not type) then
        return;
    end
    
    -- if location of sound is incuded, play only when on screen
    if(event.x and event.y)then
        --print("location sound x,y: " .. event.x .. ", " .. event.y)
        if(self:isOnScreen(event.x,event.y))then
            --print("located sound on scereen playing");
        else
            --print("located sound off screen not playing")
            return;
        end
    end
    
    
    if(type == "playnammed") then
        
        if(event.soundName) then
            self:play(event.soundName);
        end
        
    elseif(type == "button") then
        self:play("button");
        --elseif(type=="popIn") then
        --    self:playPopIn();
    else
        print("unknown sound type:" .. type);
    end
    
end

function soundManager:playButton()
    self:play("button");
end

--[[
function soundManager:playPopIn()
    
    -- measure when pop some in sound was last time played
    local time = system.getTimer();
    if((time - self.lastPopInTime) >= 40 ) then 
        
        -- choose random pop sound
        self:play(self.popSounds[rnd(1,#self.popSounds)]);
        self.lastPopInTime = time;
    end;
end
]]

function soundManager:destroy()
    
    -- release all sounds from memory
    local sounds = self.sounds;
    if(sounds) then
        for name,def in pairs(sounds) do
            audio.dispose(def.handle);   
        end
    end
    
    self.sounds = nil;
    
    if(self.soundRequestListener) then
        Runtime:removeEventListener("soundrequest", self.soundRequestListener);
        self.soundRequestListener = nil;
    end
    
end







return soundManager;



local textSource = {}

local configFile = "text.json";
local indexFile = "lang-index.json";
local basePath = "i18n/"


-- language basically the language directory
function textSource:create(langDir)
    
    self:setLanguage(langDir);
    return self;
end

function textSource:setLanguage(langDir)
    
    if(self.currentLangDir and self.currentLangDir == langDir) then
        return; 
    end
    
    
    local jsonIO = require("io.jsonIO");
    local langList = jsonIO:getTableFormFile(basePath .. indexFile);
    local defaultDir = nil--langList[1];
    
    if(self.currentLangDir) then
        defaultDir = self.currentLangDir;
    else
        defaultDir = langList[1];
    end
    
    if(langDir == nil) then langDir = defaultDir; end;
    
    local defaultLookup = true;
    
    local langSupported = false;
    for i=1,#langList do
        if(langList[i] == langDir) then
            langSupported = true;
            break;
        end
    end
    
    if(langSupported == false) then
        print("WARNING: unsupported language " .. tostring(langDir) .. ", using default " .. defaultDir);
        langDir = defaultDir;
        defaultLookup = false;
        -- the new language is not supportes amd we have the uld one used
        if(self.currentLangDir and self.currentLangDir == langDir) then
            return; -- use the same language as before
        end
    end
    
    if(langDir == langList[1]) then
        defaultLookup = false;
    end
    
    
    self.texts = jsonIO:getTableFormFile(basePath .. langDir .. "/" .. configFile);    
    
    -- load also the default language for lookups
    if(defaultLookup) then
        self.defaultTexts = jsonIO:getTableFormFile(basePath .. defaultDir .. "/" .. configFile);    
        self.defaultLookup = defaultLookup;
    end
        
    
end


function textSource:getText(key)
    local text = self.texts[key];
    
    if(text) then
        return text;
    else
        -- use default lookup
        if(self.defaultLookup) then
            text = self.defaultTexts[key];
            if(text) then
                print("Warning: text for key " .. key .. " not found in current language texts! Using default lang!")
                return text;
            end
        end
        
        return "key: " .. tostring(key) .. "  not found!";
    end
end


return textSource;


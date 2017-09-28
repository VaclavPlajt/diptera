

local maxThickness = 4;
local mockupDirectory = "mockup";
--local edgeTypesPrefs = {right="r_", up="u_"}

-- graphical theme
local Theme = {}


function Theme:new(name)
    
    local newTheme = {};
    
    setmetatable(newTheme, self);
    self.__index = self;
    
    if(name == "mockup")then
        newTheme.imgDir = mockupDirectory;
        
        local imgNamesR = {};
        local imgNamesU = {};
        local s;
        
        for i=0,maxThickness do
            s = "edge_" .. i;
            
            imgNamesR[i] = "r_" .. s;
            imgNamesU[i] = "u_" .. s;
        end
        
        self.imgNamesR = imgNamesR;
        self.imgNamesU =  imgNamesU;
        
        self.windowDecoration = {dir = "mockup/win", width=15, sideDecor = "sideDecor", endDecor="endDecor", cornerDecor="cornerDecor"};
        
    else
        error("unknown theme name: " .. name)
    end
    
    
    newTheme.playerColors = {{0.5,0.2,0.2, 0.7} ,{0.2,0.2,0.4, 0.8}};
    
    return newTheme;
end


-- returns directory, name
function Theme:getEdgeImageName(edgeType, thickness)
    
    if(edgeType == "right") then
        return self.imgDir, self.imgNamesR[thickness];
    elseif(edgeType == "up") then
        return self.imgDir, self.imgNamesU[thickness];
    else
        error("unrecognixed edge type");
    end
end

function Theme:getTileImageName()
    error("not implented yet");
end




return Theme;


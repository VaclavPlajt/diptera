-- ui constants
-- all dimension are in content pixels if not stated otherwise 
-- contains only dimensions useful for other components calculations

local smallFontSize = 18;
local normalFontSize = 24;
local bigFontSize = 28;
local hugeFontSize = 48;
local defaultFontColor = {0.71, 0.799,0.97}--{0.669, 0.763,0.95};
local highlightedFontColor = {0.74,0.324,0.634}--{0.777, 0.48,0.8};--{.91,0.48,0.25};--{0.777, 0.48,0.8}
local defaultButtonFontColor = {.085,0.095,0.43};--{0,0,0};--{1,1,1};--{.029, 0.027, 0.279};--{0.95, 0.926,0.903};--{0.95, 0.665,0.91};
local dimmedFontColor = { 1, 1, 1};

local backgroundBottomColor = {0.093,0.482,0.6189};--{0.105,0.545,0.7} --{0.126,0.49,0.618} --{ 0.303,0.525,0.605};
local backgroundTopColor = {0.95,0.657, 0.095}--{0.9,0.65,0.18}; --{0.85,0.602, 0.127}--{0.77,0.596, 0.171}--{ 0.7,0.555,0.28}; 


local defSmallBtnH = 40;
local defaultBtnH = 60;
local defBigBtnH = 80;

local uiConsts = 
{
    -- common
    defaultMargin = 5,
    uiBackAlpha = 0.4,--0.75,
    uiPaneAlpha =0.75;
    
    
    --------- MAP
    mapTileWidth = 128,
    mapBackgroundAlpha = 0.4,
    mapBackTextureSize = 512;
    maxScale = 1.25,
    minScale = 0.25,
    
    --------- Font params
    -- font sizes
    smallFontSize = smallFontSize,
    normalFontSize = normalFontSize,
    bigFontSize = bigFontSize,
    hugeFontSize = hugeFontSize,
    
    -- font name
    --fontName = native.systemFont,
    --fontName = "Kaushan Script",
    fontName = "Courgette",
    --fontName = "Duru Sans.ttf",
    --fontName = "spatny nazev fontu",
    
    -- font color
    defaultFontColor = defaultFontColor,
    highlightedFontColor = highlightedFontColor;
    
    -- Buttons 
    defaultBtnLabelColor = { default=defaultButtonFontColor, over= dimmedFontColor},
    defaultBtnFontSize = normalFontSize,
    defaultBtnHeight= defaultBtnH,
    defaultBigBtnHeight = defBigBtnH,
    defaultSmallBtnHeight = defSmallBtnH,
    
    defBtnFillColor = { default={ 0.5, 0.5, 1, 0.5 }, over={ 1, 0.5, 0.5, 0.5 } },
    defBtnStrokeColor = { default={ 0.5, 0.5, 1, 0.8 }, over={ 0.5, 0.5, 1, 1 } },
    defBtnStrokeWidth = 12,
    
    darkerBtnFillColor = { default={ 0.25, 0.25, 0.75, 0.5 }, over={ 0.5, 0.25, 0.25, 0.5 } },
    darkerBtnStrokeColor = { default={ 0.25, 0.25, 0.75, 0.8 }, over={ 0.25, 0.25, 0.5, 1 } },
    
    -- actions menu
    aMHeight = 120,
    aPanelsUpdatePeriod = 550; -- ms
    
    -- info panels 
    infoPanelBindingsWidth = 120,
    
    -- progress bar
    progressColor = backgroundTopColor,
    progressBackColor = backgroundBottomColor,
    
    
    -- minions assigner
    mAssignerFonSize = normalFontSize,
    mAssignerBtnSize = defaultBtnH, -- content pixels
        
    
    -- quick actions menu
    qSmallBtnSize = defaultBtnH,
    qBigBtnSize = defBigBtnH,
    
    -- bombardmend indicator
    biHeight = 200;
    biWidth = 30;
    
    --------- COLORS
    backgroundBottomColor = backgroundBottomColor,
    backgroundTopColor = backgroundTopColor,

    humanPlayerColor = {0.2,0.2,0.4,1},
    --aiPlayerColor =  {0.5,0.2,0.2}, 
    --aiPlayerColor =  {0.2,0.0,0.0}, 
    aiPlayerColor =  {0.413,0.146,0.658},--{0.23,0.11,0.34,0.7}, 
    --diseaseColor = {0,0,0,1};
    arrowPointerFillColor = { 0.5, 0.5, 1, 0.3 },
    arrowPointerStrokeColor = {0.5, 0.5, 1, 1},
    clusterEdgeColor =  {0.5,0.3,0.2},
}





return uiConsts;


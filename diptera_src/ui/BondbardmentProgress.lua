

local BondbardmentProgress = {}



function BondbardmentProgress:new(layer, context)
    --local gameConst = require("game.gameConst");
    
    local newBonbardmendProgress = {};
    
    -- set meta tables so lookups will work
    setmetatable(newBonbardmendProgress, self);
    self.__index = self;
    
    local uiConst = context.uiConst;
    
    local bounds = context.displayBounds;
    local margin = uiConst.defaultMargin;
    local h = uiConst.biHeight;
    local w = uiConst.biWidth;
    local top = bounds.maxY - uiConst.aMHeight - margin - h;
    local left = bounds.minX + margin;
    
    -- create ui
    newBonbardmendProgress.progressBar = require("ui.comp.ProgressBar"):new(layer, top, left, h, w,false, 1, context);
    
    newBonbardmendProgress.progressBar:setValue(0);
    
    --display.newCircle(layer,left, top, 3);
    
    
    -- listen to bombardment state changes ...
    newBonbardmendProgress.bongartmentListener = function(event) newBonbardmendProgress:onBombProgress(event) end;
    Runtime:addEventListener("bombardmentUpdate", newBonbardmendProgress.bongartmentListener)
    
    
    return newBonbardmendProgress;
end


function BondbardmentProgress:onBombProgress(event)
    self.progressBar:setValue(event.bombardment);
end
















return BondbardmentProgress;

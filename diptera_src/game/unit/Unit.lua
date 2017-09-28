

-- base unit class
local Unit = {}

--setmetatable(Unit, require("game.map.items.MapItem"))
--Unit.__index = Unit

function Unit:new(unitType)
    local newUnit = {};
    
    -- set meta tables so lookups will work
    setmetatable(newUnit, self)
    self.__index = self
    
    newUnit.unitType = unitType;
    
    return newUnit;
end

function Unit:dispatchUnitCreatedEvent(r,u)
    Runtime:dispatchEvent{name="unitCreated", unit=self, r=r, u=u};
end

function Unit:dispatchUnitDestroyedEvent()
    Runtime:dispatchEvent{name="unitDestroyed", unit=self};
end

-- called 
function Unit:initGraphics(x,y,layer, img, unitDebugLayer)
    print("default implematation of Unit:initGraphics(x,y,layer, img) - does nothing")
end







return Unit;


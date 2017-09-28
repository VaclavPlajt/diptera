
-- base class for all buildings
local Building = {};

setmetatable(Building, require("game.map.items.MapItem"))
Building.__index = Building


--Building.infoProperties = {"renderIndex", "usedIndex"}; -- properties to show in infoPanel
Building.progressProperty = {name="fitness", max="toughness"} -- property to show in infopanels progress bar


function Building:new(buildingType,r,u,map, toughness)
    local newBuilding = require("game.map.items.MapItem"):new(buildingType,r, u, map);
    
    -- set meta tables so lookups will work
    setmetatable(newBuilding, self)
    self.__index = self
    
    self.deconstructMaterialReturnRatio = require("game.gameConst").deconstructMaterialReturnRatio;
    
    newBuilding.toughness = toughness; -- max fitness
    newBuilding.fitness = toughness;
    newBuilding.repairRequestLimit  = toughness; -- repair request is send when fitnes below to this
    newBuilding.destroyed = false;
    newBuilding.isBuilding = true;
    newBuilding.deconstructonReturnsMaterial = false;
    newBuilding.repairEnabled =  true;
    
    
    return newBuilding;
end


function Building:dispatchBuildingCreatedEvent()
    Runtime:dispatchEvent{name="buildingCreated", building=self};
end

function Building:setFitness(newFitness)
    if(newFitness > self.toughness) then
        self.fitness= self.toughness;
    else
        self.fitness = newFitness;
    end
end

function Building:getOwningPlayer()
    return self.map:getTileOwner(self.r, self.u);
end


function Building:getFitness()
    return self.fitness;
end

function Building:repair(amount)
    local f = self.fitness + amount;
    
    if(f >self.tougness)then
        self.fitness = self.toughness;
    else
        self.fitness = f;
    end
    
end

function Building:initGraphics(x,y,layer, img, mapDebugLayer)
    print("Warning default implementation of Building:initGraphics() -  does nothing");
end

function Building:updateGraphics()
    print("Warning default implementation of Building:updateGraphics() -  does nothing");
end

function Building:highlightOn()
    print("Warning default implementation of Building:highlightOn() -  does nothing");
end

function Building:highlightOff()
    print("Warning default implementation of Building:highlightOff() -  does nothing");
end

function Building:destroy()
    print("Warning default implementation of Building:destroy() -  does nothing");
    self.destroyed = true;
end

function Building:playHitSound(missileType)
    -- get content coordinates
    local x,y = self.layer:localToContent(self.map.isoGrid:isoToCart(self.r,self.u));
        
    if(missileType == "Missile") then
     Runtime:dispatchEvent({name="soundrequest", type="playnammed", soundName="heal", x=x, y=y}); -- play sound   
    elseif(missileType== "EnemyMissile") then
        Runtime:dispatchEvent({name="soundrequest", type="playnammed", soundName="enemy_missile_explode", x=x, y=y}); -- play sound
    else
        print("Warning: building hit by unknown missile type:" .. tostring(missileType)); 
    end

end

function Building:showHit(damage,missileType)
    if(self.destroyed) then return 0; end;
    
    local emitterName;-- = "enemy_missile";
    
    if(missileType == "Missile") then
        emitterName = "heal";
    elseif(missileType== "EnemyMissile") then
        emitterName = "enemy_missile";
    else
        print("Warning: building hit by unknown missile type:" .. tostring(missileType)); 
    end
    
    local emitter;
    
    if(self.lastHitEmmiterName == emitterName) then
        emitter = self.lastHitEmmiter;
    else
        local x,y = self.map.isoGrid:isoToCart(self.r,self.u);
        emitter = require("ui.particles").newEmitter(emitterName);
        self.layer:insert(emitter);
        emitter.x = x;
        emitter.y = y-32;
        self.lastHitEmmiter = emitter;
        self.lastHitEmmiterName = emitterName;
        self.hitEmitterBaseDuration = emitter.duration;
    end
    
    emitter.duration = damage*self.hitEmitterBaseDuration;
    emitter:start();
end
-- returns amount of needed repairs
function Building:neededRepairs()
    
    if(self.destroyed) then return 0; end;
    
    if(self.fitness < self.toughness) then
        return self.toughness - self.fitness;
    end
    
    return 0;
end

function Building:requestRepair()
    --print("Warning default implementation of Building:requestRepair() -  does nothing");
    if(self.repairEnabled == false) then return; end;
    
    local request = {gr=self.r,gu=self.u,building=self,
    onDelivery = function() self:onRepairUnitDone() end}
    
    Runtime:dispatchEvent{name="minionActionRequest", action="repair", request = request}
    
    self.repairRequest = request;
end

function Building:cancelRepair()
    --print("Warning default implementation of Building:cancelRepair() -  does nothing");
    if(self.repairRequest) then
        self.repairRequest.state = "canceled";
        self.repairRequest= nil;
    end
end

function Building:setRepairEnabled(repairEnabled)
    self.repairEnabled = repairEnabled;
    
    if(repairEnabled == false) then
        self:cancelRepair();
    else
        self:repairIfNeeded();
    end
    
end

function Building:cancelAllRequests()
    self:cancelRepair();
end

function Building:onRepairUnitDone()
    
    if(self.destroyed) then return; end;
    
    if(self.fitness < self.toughness) then
        self.fitness = self.fitness +1;
        self:updateGraphics();
    end
    
    -- no need to keep refernece to request table, repairs are done
    if(self.fitness == self.toughness) then
        self.repairRequest = nil;
    end
    
end

function Building:repairIfNeeded()
    local owner = self:getOwningPlayer();
    local ownedByHuman = (owner ~= nil) and (owner.isAI == false);
    
    if(self.repairRequest == nil -- repair was not requested before
        and self.fitness < self.repairRequestLimit -- building needs repair
        and  ownedByHuman -- building is owned by human player
        ) then
        -- first hit, request repairs
        self:requestRepair();
    end
end

function Building:hit(damage, missileType)
    
    --if(self.destroyed or self.fitness == nil) then return; end;
    if(self.destroyed) then return; end;
    --print("hit by:" .. tostring(missileType));
    
    if(damage >= self.fitness) then 
        self.fitness = 0;
        self:destroy();
    else        
        self.fitness = self.fitness - damage;
        
        self:repairIfNeeded();
        self:updateGraphics();
        self:playHitSound(missileType);
        self:showHit(damage,missileType);
    end
    
end

function Building:returnMaterial()
    
    --print("Building:returnMaterial()")
    -- building have to be destroyed by deconstruction to return material
    if(not (self.destroyed and self.inDeconstruction)) then return; end;
    
    local gameConst = require("game.gameConst");
    
    local cost  = gameConst[self.typeName].materialCost;
    
    local amount = math.floor(self.deconstructMaterialReturnRatio * cost);
    --print("returning  material")
    if(amount > 0) then
        require("game.map.items.Material"):new(self.r, self.u ,amount,self.map);
    end
    
    
end

-- starts building deconstructin
function Building:deconstruct()
    
    if(self.inDeconstruction) then return; end
    
    self.inDeconstruction = true;
    
    local request = {gr=self.r,gu=self.u,amount=1,
        onDelivery = function() 
            self:destroy();
            if(self.deconstructonReturnsMaterial) then
                self:returnMaterial();
            end
    end}
    
    Runtime:dispatchEvent{name="minionActionRequest", action="work", request = request}
end


return Building;





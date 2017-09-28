--see http://coronalabs.com/blog/2013/01/22/implementing-pinch-zoom-rotate/
local PlayerInput = {};

local distFun = require("math.geometry").manhattanDist;
--local maxScale = 1.0;
--local minScale = 0.25;

-- which environment are we running on?
local isDevice = (system.getInfo("environment") == "device")
local keepDotsOnDevice = false;

local removeDots = isDevice or not keepDotsOnDevice;

-- returns the distance between points a and b
local function lengthOf( a, b )
    local width, height = b.x-a.x, b.y-a.y
    return (width*width + height*height)^0.5
end

-- calculates the average centre of a list of points
local function calcAvgCentre( points )
    local x, y = 0, 0
    
    for i=1, #points do
        local pt = points[i]
        x = x + pt.x
        y = y + pt.y
    end
    
    return { x = x / #points, y = y / #points }
end

-- calculate each tracking dot's distance and angle from the midpoint
local function updateTracking( centre, points )
    for i=1, #points do
        local point = points[i]
        
        point.prevDistance = point.distance
        
        point.distance = lengthOf( centre, point )
    end
end

-- calculates scaling amount based on the average change in tracking point distances
local function calcAverageScaling( points )
    local total = 0
    
    for i=1, #points do
        local point = points[i]
        total = total + point.distance / point.prevDistance
    end
    
    return total / #points
end

-- limits = {minX, maxX, minY, maxY, minScale, maxScale}
function PlayerInput:new(context, inputLayer, mapLayer, isoGrid, limits)
    
    
    local newPlayerInput = {};
    
    setmetatable(newPlayerInput, self);
    self.__index = self; 
    
    local bounds = context.displayBounds;
    newPlayerInput.inputLayer = inputLayer;
    newPlayerInput.context = context;
    --self.mapGraphics = mapGraphics;
    newPlayerInput.mapLayer = mapLayer;
    newPlayerInput.isoGrid = isoGrid;
    newPlayerInput.limits = limits;
    
    system.activate( "multitouch" );
    
    newPlayerInput.dots = {};
    
    -- tap detection
    newPlayerInput.tapId = nil;
    newPlayerInput.tapTime = nil;
    newPlayerInput.tapX = 0;
    newPlayerInput.tapY = 0;
    
    -- add map covering touch event dotector to scale and translate
    local bottomMargin = context.uiConst.aMHeight;
    local h = bounds.height - bottomMargin;
    local touchDetector = display.newRect(inputLayer, bounds.centerX, bounds.centerY-0.5*bottomMargin, bounds.width, h);
    newPlayerInput.touchDetector = touchDetector;
    touchDetector.isVisible = false;
    touchDetector.isHitTestable = true;
    --touchDetector:setFillColor(0.2,0.3,0.7, 0.35);
    
    touchDetector:addEventListener( "touch", function(event) newPlayerInput:touch(event) end );
    
    return newPlayerInput;
end


function PlayerInput:destroy()
    self.mapLayer = nil;
    self.touchDetector:removeSelf();
    self.touchDetector = nil;
end

function PlayerInput:setMapLayer(newMapLayer)
    self.mapLayer = newMapLayer;
end


function PlayerInput:scaleIn()
    
    local scale = 1.25;
    --print("scaleIn, before: " .. self.mapLayer.xScale .. ", after:" .. scale)
    self:scaleMap(scale);
end

function PlayerInput:scaleOut()    
    local scale = 0.75;
    --print("scaleout, before: " .. self.mapLayer.xScale .. ", after:" .. scale)
    self:scaleMap(scale);
end

function PlayerInput:scaleMap(scale)
    local limits = self.limits;
    local xScale, yScale = self.mapLayer.xScale * scale, self.mapLayer.yScale * scale;
    
    if(limits) then
        
        if(xScale > limits.maxScale) then
            xScale = limits.maxScale
        elseif(xScale < limits.minScale) then
            xScale = limits.minScale
        end
        
        if(yScale > limits.maxScale) then
            yScale = limits.maxScale
        elseif(yScale < limits.minScale) then
            yScale = limits.minScale
        end
    end
    
    --    print(" s:" .. xScale)
    -- apply scaling to rect
    --self.touchDetector.xScale, self.touchDetector.yScale = self.touchDetector.xScale * scale, self.touchDetector.yScale * scale
    self.mapLayer.xScale, self.mapLayer.yScale = xScale, yScale;
    
end

-- advanced multi-touch event listener
function PlayerInput:touch(e)
    -- get the object which received the touch event
    local target = e.target;
    
    -- handle began phase of the touch event life cycle...
    if (e.phase == "began") then
        --print( e.phase, e.x, e.y )
        
        -- create a tracking dot
        local dot = self:newTrackDot(e)
        
        -- add the new dot to the list
        self.dots[ #self.dots+1 ] = dot;
        
        -- pre-store the average centre position of all touch points
        self.prevCentre = calcAvgCentre( self.dots )
        
        -- pre-store the tracking dot scale and rotation values
        updateTracking( self.prevCentre, self.dots )
        
        -- remeber some dat for tap detection
        self.tapId = e.id;  self.tapTime = system.getTimer();
        self.tapX = e.x; self.tapY = e.y;
        
        -- we handled the began phase
        return true
    elseif (e.parent == self.touchDetector) then
        if (e.phase == "moved") then
            --print( e.phase, e.x, e.y )
            
            -- declare working variables
            local centre, scale, rotate = {}, 1, 0
            --local limits = self.limits;
            
            -- calculate the average centre position of all touch points
            centre = calcAvgCentre( self.dots )
            
            -- refresh tracking dot scale and rotation values
            updateTracking( self.prevCentre, self.dots )
            
            -- if there is more than one tracking dot, calculate the rotation and scaling
            if (#self.dots > 1) then
                -- calculate the average scaling of the tracking dots
                scale = calcAverageScaling( self.dots )
                self:scaleMap(scale);
            end
            
            -- update the position of rect
            --self.touchDetector.x = self.touchDetector.x + (centre.x - self.prevCentre.x)
            --self.touchDetector.y = self.touchDetector.y + (centre.y - self.prevCentre.y)
            --self.mapLayer.x = self.mapLayer.x + (centre.x - self.prevCentre.x)
            --self.mapLayer.y = self.mapLayer.y + (centre.y - self.prevCentre.y)
            
            local x = self.mapLayer.x + (centre.x - self.prevCentre.x);
            local y = self.mapLayer.y + (centre.y - self.prevCentre.y);
            local limits = self.limits;
            if(limits) then
                --print("x,y:" .. x .. ", " .. y .. " maxX:" .. tostring(limits.maxX) .. ", minX" .. tostring(limits.minX));
                --print("xScale,yScale:" .. self.mapLayer.xScale .. ", " .. self.mapLayer.xScale .. " maxScale:" .. tostring(limits.maxScale) .. ", minScale" .. tostring(limits.minScale));
                if(x > limits.maxX)then
                    x = limits.maxX;
                    --print("limit: maxX");
                elseif(x < limits.minX) then
                    x = limits.minX;
                    --print("limit: minX");
                end
                
                if(y > limits.maxY)then
                    y = limits.maxY;
                    --print("limit: maxY");
                elseif(y < limits.minY) then
                    y = limits.minY;
                    --print("limit: minY");
                end
            end
            self.mapLayer.x = x;
            self.mapLayer.y = y;
            --print("x:" .. x)
            
            -- store the centre of all touch points
            self.prevCentre = centre
        else -- "ended" and "cancelled" phases
            --print( e.phase, e.x, e.y )
            
            -- remove the tracking dot from the list
            if (removeDots or e.numTaps == 2) then
                -- get index of dot to be removed
                local index = table.indexOf( self.dots, e.target )
                
                -- remove dot from list
                table.remove( self.dots, index )
                
                -- remove tracking dot from the screen
                e.target:removeSelf()
                
                -- store the new centre of all touch points
                self.prevCentre = calcAvgCentre( self.dots )
                
                -- refresh tracking dot scale and rotation values
                updateTracking( self.prevCentre, self.dots )
            end
            
            -- detect tap
            if(self.tapId == e.id and system.getTimer()-self.tapTime < 350) then
                local dist = distFun(self.tapX,self.tapY, e.x,e.y);
                if(dist <= 15)then
                    --print("tap");
                    if(self.isoGrid) then
                        self:dispatchTileTapped(e.x,e.y)
                    end
                end
            end
            
            
        end
        return true
    end
    
    -- if the target is not responsible for this touch event return false
    return false
end


-- spawning tracking dots
-- creates an object to be moved
function PlayerInput:newTrackDot(e)
    -- create a user interface object
    local circle = display.newCircle( e.x, e.y, 25 )
    
    -- make it less imposing
    --circle.alpha = .4
    circle.isVisible = false;
    circle.isHitTestable = true;
    
    -- keep reference to the rectangle
    local touchTarget = e.target
    
    local outerSelf = self;
    
    -- standard multi-touch event listener
    function circle:touch(e)
        -- get the object which received the touch event
        local target = circle
        
        -- store the parent object in the event
        e.parent = touchTarget;
        
        -- handle each phase of the touch event life cycle...
        if (e.phase == "began") then
            -- tell corona that following touches come to this display object
            display.getCurrentStage():setFocus(target, e.id)
            -- remember that this object has the focus
            target.hasFocus = true;
            -- indicate the event was handled
            return true
        elseif (target.hasFocus) then
            -- this object is handling touches
            if (e.phase == "moved") then
                -- move the display object with the touch (or whatever)
                target.x, target.y = e.x, e.y
            else -- "ended" and "cancelled" phases
                -- stop being responsible for touches
                display.getCurrentStage():setFocus(target, nil)
                -- remember this object no longer has the focus
                target.hasFocus = false
            end
            
            -- send the event parameter to the rect object
            outerSelf:touch(e)
            
            -- indicate that we handled the touch and not to propagate it
            return true
        end
        
        -- if the target is not responsible for this touch event return false
        return false
    end
    
    -- listen for touches starting on the touch layer
    circle:addEventListener("touch")
    
    -- listen for a tap when running in the simulator
    function circle:tap(e)
        
        if (e.numTaps == 2) then
            -- set the parent
            e.parent = touchTarget
            
            -- call touch to remove the tracking dot
            outerSelf:touch(e)
            --else
            --    print("tap");
            --    outerSelf:dispatchTileTapped(e.x,e.y)
        end
        return true
    end
    
    -- only attach tap listener in the simulator
    if (not isDevice) then
        circle:addEventListener("tap")
    end
    
    -- pass the began phase to the tracking dot
    circle:touch(e)
    
    -- return the object for use
    return circle
end

function PlayerInput:dispatchTileTapped(x,y)
    local isoGrid = self.isoGrid;
    
    --local xl, yl = self.mapGraphics:contentToLocal(x, y);
    
    local xl, yl = self.mapLayer:contentToLocal(x, y);
    
    
    local r,u = isoGrid:cartToIso(xl,yl);
    --print("[r,u]: [" .. r .. ", " .. u .. "] node");
    
    if(r>0 and u >0 and r <= isoGrid.size and u <= isoGrid.size) then
        Runtime:dispatchEvent({name = "tiletapped", r = r, u= u});
    end
end



return PlayerInput;


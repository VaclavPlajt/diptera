-- simple 2d map implementation
-- fast member check, fast adding, fast removing
local assert, setmetatable = assert, setmetatable

local Map2D = {}


function Map2D:new()
    local newMap = {};
    
    setmetatable(newMap, self);
    self.__index = self;
    
    return newMap;
end


-- if item [key1, key2] already exists in map, it will be overwritten
function Map2D:add(key1, key2, value)
    local map = self;
    
    if(map[key1]) then -- there is a item with this key in map
        
        if(map[key1][key2]) then -- there is the same item in map
            map[key1][key2] = value; -- overwrite
        else -- the item with given key2 is not in map yet
            -- add symbol
            map[key1][key2] = value;
        end
        
    else -- no item with key1, key2 is in map
        map[key1] = {};
        map[key1][key2]=value;
    end
    
end

-- removes item from map, no returning value
function Map2D:remove(key1, key2)
    local map = self;  
    
       
    if(map[key1] and map[key1][key2]) then -- there is a item with key1, key2
        
        -- erease item form map
        map[key1][key2] = nil;
        
    else -- the symbol prom this set is not in map !
        print("Warning - trying to remove a non existing item fom map! [key1, key2]: [" .. key1 .. ", " .. key2 .. " ]");
    end
    
end

-- returns true when map contains item with given keys, fale otherwise
function Map2D:contains(key1, key2)
    local map = self;  
    
       
    if(map[key1] and map[key1][key2]) then -- there is a item with key1, key2
        
        return true;
        
    else -- the symbol prom this set is not in map !
        return false
    end
    
end

-- remove item from map and returns its value or nil when no item with was found
function Map2D:retrieve(key1, key2)
    local map = self;  
    
    if(map[key1] and map[key1][key2]) then -- there is a item with key1, key2
        
        local val = map[key1][key2];
        -- erease item form map
        map[key1][key2] = nil;
        
        return val;
        
    else -- the symbol prom this set is not in map !
        print("Warning - trying to retrieve a non existing item fom map! [key1, key2]: [" .. key1 .. ", " .. key2 .. " ]");
        return nil;
    end
end

-- returns value of item with given keys
-- or nil when item cannot be found
function Map2D:get(key1, key2)
    local map = self;  
    
    if(map[key1] and map[key1][key2]) then -- there is a item with key1, key2
        
        return map[key1][key2];
        
    else -- the symbol prom this set is not in map !
        --print("Warning - trying to retrieve a non existing item fom map! [key1, key2]: [" .. key1 .. ", " .. key2 .. " ]");
        return nil;
    end
end

-- Map2D:iterate(callback)
-- callback function called each iteration with (key1, key2, value) parameters
-- iterates through map
-- iteration stops when callback returns true or end of map is reached
--
function Map2D:iterate(callback)
    local map = self;  
    
    for key1, v1 in pairs(map) do
        for key2, v2 in pairs(v1) do
            if(callback(key1, key2, v2))then
                return;
            end
        end
    end
    
end

-- clears all contaning data
function Map2D:clear()
    local map = self;  
    
    for key1, v1 in pairs(map) do
        for key2, v2 in pairs(v1) do
            v1[key2] = nil;
        end
    end
    
end

return Map2D;


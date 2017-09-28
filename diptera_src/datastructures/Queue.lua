

local Queue = {}

function Queue:new()
    
    local o = {}   -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    
    o.first = 0;
    o.last = -1;
    return o
end


function Queue:push(value)
    local last = self.last + 1
    self.last = last
    self[last] = value
end

function Queue:pop()
    local first = self.first
    if first > self.last then
        --error("list is empty")
        return nil;
    end
    
    local value = self[first]
    self[first] = nil        -- to allow garbage collection
    self.first = first + 1
    return value
end

-- returns all items in queue
function Queue:popAll()
    local first = self.first
    if first > self.last then
        --error("list is empty")
        return nil;
    end
    
    local items = {};
    for i=first, self.last do
        local value = self[i]
        self[i] = nil        -- to allow garbage collection
        --self.first = first + 1
        items[#items+1] = value;
        
    end
    
    self.first = self.last+1;
    return items;
end

function Queue:isEmpty()
    return self.first > self.last;
end

function Queue:getSize()
    return self.last- self.first +1;
end


-- see: http://www.lua.org/pil/11.4.html
--Now, we can insert or remove an element at both ends in constant time:

function Queue:pushFirst(value)
    local first = self.first - 1
    self.first = first
    self[first] = value
end

function Queue:popLast()
    local last = self.last
    if self.first > last then error("list is empty") end
    local value = self[last]
    self[last] = nil         -- to allow garbage collection
    self.last = last - 1
    return value
end

--[[
-- the same as Queue:push()
function Queue:pushright(value)
    local last = self.last + 1
    self.last = last
    self[last] = value
end

-- the same as Queue:pop()
function Queue:popleft()
    local first = self.first
    if first > self.last then error("list is empty") end
    local value = self[first]
    self[first] = nil        -- to allow garbage collection
    self.first = first + 1
    return value
end

]]

return Queue;

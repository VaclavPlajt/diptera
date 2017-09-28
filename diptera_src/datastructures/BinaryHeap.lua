-- Heap.lua
-- a priority queue implementation
-- refer to:
-- http://interactivepython.org/runestone/static/pythonds/Trees/heap.html#lst-heap1
-- https://github.com/Yonaba/Binary-Heaps
local assert, setmetatable = assert, setmetatable

--module(...)

local BinaryHeap = {};

local floor = math.floor;

function BinaryHeap:new()
    local newHeap = {heapList = {}, currentSize = 0};
    
    setmetatable(newHeap, self);
    self.__index = self;
    
    return newHeap;
end


function BinaryHeap:percUp(i)
    local n = floor(i / 2);
    
    while  n > 0 do
        if self.heapList[i][1] < self.heapList[n][1] then
            local tmp = self.heapList[n]
            self.heapList[n] = self.heapList[i]
            self.heapList[i] = tmp
	end
        i = floor(i / 2);
        n = floor(i / 2);
    end
end

function BinaryHeap:percDown(i)
    while (i * 2) <= self.currentSize do
        local mc = self:minChild(i)
        if self.heapList[i][1] > self.heapList[mc][1] then
            local tmp = self.heapList[i]
            self.heapList[i] = self.heapList[mc]
            self.heapList[mc] = tmp
        end
        i = mc;
    end
end

-- BinaryHeap:insert(k,v)
-- k - key, inverse priority or cost
-- v - value or stored data
function BinaryHeap:insert(k,v)
    
    self.currentSize = self.currentSize + 1
    self.heapList[self.currentSize] = {k,v};
    self:percUp(self.currentSize);
end

function BinaryHeap:minChild(i)
    
    if i * 2 + 1 > self.currentSize then
        return i * 2
    else
        if self.heapList[i*2][1] < self.heapList[i*2+1][1] then
            return i * 2
        else
            return i * 2 + 1;
        end
    end
end

-- BinaryHeap:delMin()
-- deletes item with minimal key from heap
-- returns key, value of minimal item
function BinaryHeap:delMin()
    if(self.currentSize > 0) then
        local retval = self.heapList[1]
        self.heapList[1] = self.heapList[self.currentSize]
        self.heapList[self.currentSize] = nil;
        self.currentSize = self.currentSize - 1
        self:percDown(1)
        return retval[1],retval[2];
    else
        return nil, nil;
    end
end

function BinaryHeap:buildHeap(alist)
    local i = floor(#alist / 2);
    self.currentSize = #alist;
    
    for j = 1, #alist do
        self.heapList[j] = alist[j];
    end
    
    while (i > 0) do
        self:percDown(i)
        i = i - 1
    end
end

-- BinaryHeap:changeKey(k,v, newK)
-- changes key of existing item to given new key
-- the item is identified by both k and v values
-- does nothing when exact k, v item is not found
-- has compplexity O(n)
function BinaryHeap:changeKey(k,v, newK)
    local i = 1;
    local nf = true; -- not found
    
    while(i < self.currentSize and nf) do
        if( self.heapList[i][1] == k and self.heapList[i][2] == v) then
            nf = false; 
        else
            i=i+1;
        end
        
        
    end
    
    if(not nf) then
        self.heapList[i][1] = newK; -- change key
        
        if(newK > k ) then
            self:percDown(i);
        else
            self:percUp(i);
        end
        
    end
end


function BinaryHeap:size()
    return self.currentSize;
end

function BinaryHeap:isEmpty()
    return self.currentSize <= 0;
end

function BinaryHeap:clear()
    self.currentSize = 0;
end


return BinaryHeap;

local LinkedList = {}



function LinkedList:new()
    local newList = {};

    -- set meta tables so lookups will work
    setmetatable(newList, self)
    self.__index = self

    newList.count =  0;
    newList.head = nil;
    newList.tail =  nil;
    newList.current = nil;
    newList.previous = nil;

    return newList;

end

function LinkedList:addFirst(value)
    local item  = {next=self.head, value=value};

    self.head = item;

	if(self.tail == nil) then
		self.tail = item;
	end

    self.count = self.count + 1;
end

function LinkedList:addLast(value)
    local item  = {next=nil, value=value};

	if(self.tail) then
		self.tail.next = item;
		self.tail = item;
	else
		self.head = item;
		self.tail = item;
	end

    self.count = self.count + 1;
end

function LinkedList:getSize()
    return self.count;
end

function LinkedList:resetIteration()
    self.current = nil;
    self.previous = nil;
end

function LinkedList:getNext()
	local item;

	if(self.current) then
		item = self.current.next;
	else
		item = self.head;
	end

    if(item) then
        self.previous = self.current;
        self.current = item;
        return item.value;
    end

    return nil;

end

function LinkedList:removeCurrent()
    if(self.current) then

		-- is the current in fact the head?
        if(self.current == self.head) then
            self.head = self.current.next;

			-- if list has one item
			if(self.current == self.tail) then
				self.tail = nil;
			end

			self.current = nil;
        elseif(self.current == self.tail) then
			-- more than one item in list, but current is the tail
            self.tail = self.previous;
			self.current =  self.previous;
			self.previous.next = nil;
        else
			-- current item is somewere in the middle of the list
			self.previous.next = self.current.next;
			self.current = self.previous;
        end

	self.count = self.count - 1;


    end
end


return LinkedList;


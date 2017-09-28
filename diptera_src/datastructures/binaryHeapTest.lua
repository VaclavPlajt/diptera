

local heap =  require("datastructures.BinaryHeap"):new();
local dataList = {};

-- otestovat pridani vic stejnych klicu !!!

for i=1, 6 do
    local data = math.random();
    dataList[i] =  data;
    
    heap:insert(i, data);
end


heap:insert(5, -25);
heap:insert(5, math.random());
heap:insert(5, math.random());

heap:changeKey(5,dataList[5], 11);
heap:changeKey(4,dataList[4], 0);

heap:changeKey(5,-25, -25);
heap:changeKey(4,dataList[4], 0);

heap:changeKey(11,dataList[5], 5.5);

while(not heap:isEmpty()) do
    print( heap:delMin());
end

return heap;


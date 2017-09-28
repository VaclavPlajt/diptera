

local geometryMath = require("math.geometry"); 

print("spiral search test")
local printOutFnc =  function(x,y) print(x .. ", " .. y) return false; end;

geometryMath.spiral_search(0,0,3, printOutFnc);


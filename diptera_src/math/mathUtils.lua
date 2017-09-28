

local mathUtils = {};

local rnd =  math.random;
local abs = math.abs;
local log = math.log;

function mathUtils.randomBool(probability)
    
    
    return rnd() <= probability;
    
    --[[
    if(rnd(1000) <= (probability*1000)) then
        return true;
    else
        return false
    end;
    ]]
end



-- returns random number drwan from N(mean, sigma) normal distibution
-- mean - mean value (also median and mode)
-- sigma - standart deviation, variance square root
-- About 68% of values drawn from a normal distribution are within one standard deviation σ away
-- from the mean; about 95% of the values lie within two standard deviations;
-- and about 99.7% are within three standard deviations.
-- This fact is known as the 68-95-99.7 (empirical) rule, or the 3-sigma rule.
function mathUtils.normalDev(mean, sigma) -- return a normal deviate
	local u,v,x,y,q;

	repeat
		u = rnd();
		v = 1.7156*(rnd()-0.5);
		x = u - 0.449871;
		y = abs(v) + 0.386595;
		q = x*x + y*(0.19600*y-0.25472*x);
	until ( not( q > 0.27597 and
				( q > 0.27846 or v*v < -4*log(u)*u*u)));

	return mean + sigma*v/u;

end


return mathUtils;


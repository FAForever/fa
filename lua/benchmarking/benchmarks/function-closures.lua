
-- ClosureA: 106 ms
-- ClosureB: 62.5 ms

-- Creation closures on the go is expensive, but not as time consuming 
-- as it appears to be within the Supreme Commander context.

local outerLoop = 1000000

function ClosureA()
    local func1 = function(a,b,func) 
        return func(a+b) 
    end

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for i=1, outerLoop do
        local x = func1(1,2,function(a) return a*2 end)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function ClosureB()
    local func1 = function(a,b,func) 
        return func(a+b) 
    end

    local func2 = function(c) 
        return c*2 
    end
    
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for i=1, outerLoop do
        local x = func1(1,2,func2)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end
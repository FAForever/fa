
function ClosureA()
    local func1 = function(a,b,func) 
        return func(a+b) 
    end

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for i=1,100000 do
        local x = func1(1,2,function(a) return a*2 end)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function ClosureB()
    local func1 = function(a,b,func) 
        return func(a+b) 
    end

    local func2 = function(a) 
        return a*2 
    end
    
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for i=1,100000 do
        local x = func1(1,2,func2)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

-- ClosureA: 106 ms
-- ClosureB: 62.5 ms

-- Creation closures on the go is expensive, but not as time consuming 
-- as it appears to be within the Supreme Commander context.

ModuleName = "Function Closures"
BenchmarkData = {
    ClosureA = "Closure A",
    ClosureB = "Closure B",
}

function ClosureA(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local func1 = function(a, b, func)
        return func(a + b)
    end

    local start = timer()

    for _ = 1, loop do
        func1(1, 2, function(a) return a * 2 end)
    end

    local final = timer()
    return final - start
end

function ClosureB(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local func1 = function(a, b, func)
        return func(a + b)
    end

    local start = timer()

    local func2 = function(c)
        return c*2
    end

    for _ = 1, loop do
        func1(1, 2, func2)
    end

    local final = timer()
    return final - start
end
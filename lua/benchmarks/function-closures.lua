
-- Results with parameters 10000:
--
-- |-------------------------|---------|---------|------------|-----------|--------|-------|-----------|--------|--------|------|
-- | Name                    | Samples | Mean ms | +/- 95% ms | +/- 95% % | Dev ms |  CV % | Median ms | Min ms | Max ms | Skew |
-- |-------------------------|---------|---------|------------|-----------|--------|-------|-----------|--------|--------|------|
-- | "New closure per call"  |      25 |  0.5386 |     0.0047 |      0.88 | 0.0114 |  2.12 |    0.5341 | 0.5264 | 0.5646 | 0.74 |
-- | "Closure created once"  |      28 |  0.3967 |     0.0029 |      0.73 | 0.0075 |  1.89 |    0.3967 | 0.3891 | 0.4196 | 1.13 |
-- |-------------------------|---------|---------|------------|-----------|--------|-------|-----------|--------|--------|------|
-- | "Baseline, 1 parameter" |      60 |  0.0389 |     0.0016 |      4.14 | 0.0062 | 16.02 |    0.0381 | 0.0305 | 0.0687 | 2.39 |
-- |-------------------------|---------|---------|------------|-----------|--------|-------|-----------|--------|--------|------|

-- Passing a new closure on each call is 1.36x slower than passing one created before the loop,
-- about 14 ns per closure. Creating closures on the go is expensive, but not as time consuming as it
-- appears to be within the Supreme Commander context.

ModuleName = "Function Closures"
ModuleLoopCount = 100000
BenchmarkData = {
    ClosureA = "New closure per call",
    ClosureB = "Closure created once",
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
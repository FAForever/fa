
-- Results with loop count 100000:
--
-- |-------------------------|---------|---------|------------|-----------|--------|------|-----------|--------|--------|------|
-- | Name                    | Samples | Mean ms | +/- 95% ms | +/- 95% % | Dev ms | CV % | Median ms | Min ms | Max ms | Skew |
-- |-------------------------|---------|---------|------------|-----------|--------|------|-----------|--------|--------|------|
-- | "New closure per call"  |      30 |  5.9392 |     0.0248 |      0.42 | 0.0664 | 1.12 |    5.9357 | 5.8136 | 6.0883 | 0.17 |
-- | "Closure created once"  |      25 |  4.0271 |     0.0091 |      0.23 | 0.0220 | 0.55 |    4.0283 | 3.9978 | 4.0741 | 0.29 |
-- |-------------------------|---------|---------|------------|-----------|--------|------|-----------|--------|--------|------|
-- | "Baseline, 1 parameter" |      61 |  0.3792 |     0.0040 |      1.06 | 0.0157 | 4.15 |    0.3815 | 0.3510 | 0.4120 | 0.65 |
-- |-------------------------|---------|---------|------------|-----------|--------|------|-----------|--------|--------|------|

-- Passing a new closure on each call is 1.47x slower than passing one created before the loop,
-- about 19 ns per closure. Creating closures on the go is expensive, but not as time consuming as it
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
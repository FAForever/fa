-- Results with parameters 10000:
--
-- |----------------------------------|---------|---------|------------|-----------|--------|-------|-----------|--------|--------|------|
-- | Name                             | Samples | Mean ms | +/- 95% ms | +/- 95% % | Dev ms |  CV % | Median ms | Min ms | Max ms | Skew |
-- |----------------------------------|---------|---------|------------|-----------|--------|-------|-----------|--------|--------|------|
-- | "UpvaluedEngineVDist2OnLocals"   |      28 |  0.3466 |     0.0058 |      1.67 | 0.0149 |  4.30 |    0.3357 | 0.3357 | 0.3662 | 0.56 |
-- | "UpvaluedEngineVDist2SqOnLocals" |      30 |  0.3459 |     0.0156 |      4.52 | 0.0419 | 12.11 |    0.3357 | 0.3052 | 0.5493 | 3.82 |
-- | "UpvaluedLuaVDist2OnLocals"      |      19 |  0.2747 |     0.0000 |      0.00 | 0.0000 |  0.00 |    0.2747 | 0.2747 | 0.2747 | 0.00 |
-- | "UpvaluedLuaVDist2SqOnLocals"    |      29 |  0.1326 |     0.0056 |      4.23 | 0.0148 | 11.13 |    0.1221 | 0.1221 | 0.1526 | 0.62 |
-- |----------------------------------|---------|---------|------------|-----------|--------|-------|-----------|--------|--------|------|
-- | "Baseline, 1 parameter"          |     120 |  0.0381 |     0.0024 |      6.29 | 0.0133 | 34.79 |    0.0305 | 0.0305 | 0.0610 | 1.14 |
-- |----------------------------------|---------|---------|------------|-----------|--------|-------|-----------|--------|--------|------|
--
-- These are too short for the timer, so they mostly show its step: "UpvaluedEngineVDist2OnLocals",
-- "UpvaluedEngineVDist2SqOnLocals", "UpvaluedLuaVDist2OnLocals", "UpvaluedLuaVDist2SqOnLocals".

-- Conclusion: Lua is much faster, especially when skipping the square root (useful in distance comparisons).

ModuleName = "VDist2"
ModuleLoopCount = 200000

function UpvaluedEngineVDist2OnLocals(loop)
    local p1 = Random()*1000
    local p2 = Random()*1000
    local p3 = Random()*1000
    local p4 = Random()*1000

    -- upvalue
    local VDist2 = VDist2

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for i=1, loop do
        local dist = VDist2(p1, p2, p3, p4)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function UpvaluedEngineVDist2SqOnLocals(loop)
    local p1 = Random()*1000
    local p2 = Random()*1000
    local p3 = Random()*1000
    local p4 = Random()*1000

    -- upvalue
    local VDist2Sq = VDist2Sq

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for i=1, loop do
        local dist = VDist2Sq(p1, p2, p3, p4)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function UpvaluedLuaVDist2OnLocals(loop)
    local p1 = Random()*1000
    local p2 = Random()*1000
    local p3 = Random()*1000
    local p4 = Random()*1000

    -- upvalue
    local MathSqrt = math.sqrt

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for i=1, loop do
        local d1 = p3 - p1
        local d2 = p4 - p2
        local dist = MathSqrt(d1 * d1 + d2 * d2)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function UpvaluedLuaVDist2SqOnLocals(loop)
    local p1 = Random()*1000
    local p2 = Random()*1000
    local p3 = Random()*1000
    local p4 = Random()*1000

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for i=1, loop do
        local d1 = p3 - p1
        local d2 = p4 - p2
        local dist = d1 * d1 + d2 * d2
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

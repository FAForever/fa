-- Results with loop count 200000:
--
-- |---------------------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|------|
-- | Name                                  | Samples | Mean ms | +/- 95% ms | +/- 95% % | Dev ms | CV % | Median ms |  Min ms |  Max ms | Skew |
-- |---------------------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|------|
-- | "UpvaluedEngineVDist2OnLocals (x2)"   |      29 | 14.0465 |     0.1996 |      1.42 | 0.5247 | 3.74 |   13.8550 | 13.4277 | 15.1978 | 0.68 |
-- | "UpvaluedEngineVDist2SqOnLocals (x2)" |      30 | 13.6434 |     0.3605 |      2.64 | 0.9655 | 7.08 |   13.3362 | 12.3291 | 15.6860 | 0.52 |
-- | "UpvaluedLuaVDist2OnLocals (x2)"      |      29 | 10.1129 |     0.0407 |      0.40 | 0.1071 | 1.06 |   10.1318 |  9.9487 | 10.3760 | 0.42 |
-- | "UpvaluedLuaVDist2SqOnLocals (x2)"    |      32 |  5.0964 |     0.0407 |      0.80 | 0.1139 | 2.24 |    5.0659 |  4.8218 |  5.3101 | 0.14 |
-- |---------------------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|------|
-- | "Baseline, 1 parameter (x2)"          |     107 |  1.5071 |     0.0081 |      0.54 | 0.0423 | 2.80 |    1.5259 |  1.4648 |  1.5869 | 0.48 |
-- |---------------------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|------|

-- Conclusion: Lua is much faster, especially when skipping the square root (useful in distance comparisons).
-- `VDist2` in Lua is 1.4x faster than the engine's, and `VDist2Sq` in Lua 2.7x faster.

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

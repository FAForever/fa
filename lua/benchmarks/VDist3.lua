-- Results with loop count 100000:
--
-- |---------------------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|-------|
-- | Name                                  | Samples | Mean ms | +/- 95% ms | +/- 95% % | Dev ms | CV % | Median ms |  Min ms |  Max ms |  Skew |
-- |---------------------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|-------|
-- | "GlobalEngineVDist3OnUpvalues (x2)"   |      28 | 12.9046 |     0.0766 |      0.59 | 0.1976 | 1.53 |   12.8174 | 12.6953 | 13.3667 |  0.80 |
-- | "GlobalEngineVDist3OnLocals (x2)"     |      29 | 12.9226 |     0.0614 |      0.47 | 0.1614 | 1.25 |   12.9395 | 12.6953 | 13.1836 |  0.03 |
-- | "GlobalLuaVDist3OnUpvalues (x2)"      |      27 | 14.6213 |     0.0420 |      0.29 | 0.1062 | 0.73 |   14.6484 | 14.4043 | 14.8315 | -0.09 |
-- | "GlobalLuaVDist3OnLocals (x2)"        |      28 | 12.5558 |     0.0554 |      0.44 | 0.1428 | 1.14 |   12.5122 | 12.3291 | 12.8784 |  0.53 |
-- | "UpvaluedEngineVDist3OnUpvalues (x2)" |      28 | 12.0762 |     0.0494 |      0.41 | 0.1273 | 1.05 |   12.0544 | 11.8408 | 12.3291 |  0.18 |
-- | "UpvaluedEngineVDist3OnLocals (x2)"   |      26 | 12.0028 |     0.0319 |      0.27 | 0.0790 | 0.66 |   12.0239 | 11.8408 | 12.1460 |  0.10 |
-- | "UpvaluedLuaVDist3OnUpvalues (x2)"    |      25 | 12.5903 |     0.1116 |      0.89 | 0.2704 | 2.15 |   12.5122 | 12.3291 | 13.1836 |  0.95 |
-- | "UpvaluedLuaVDist3OnLocals (x2)"      |      26 | 10.6835 |     0.1332 |      1.25 | 0.3296 | 3.08 |   10.6201 | 10.2539 | 11.3525 |  0.57 |
-- |---------------------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|-------|
-- | "Baseline, 1 parameter (x2)"          |     221 |  0.7512 |     0.0046 |      0.62 | 0.0352 | 4.68 |    0.7324 |  0.6714 |  0.7935 | -0.14 |
-- |---------------------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|-------|

-- Conclusion: on local vectors, calculating in Lua with an upvalued `math.sqrt` is 11% faster than an
-- upvalued VDist3. On vectors in upvalues, the upvalued VDist3 is 4% faster. An engine patch sped
-- up VDist3: https://github.com/FAForever/FA-Binary-Patches/pull/54
-- Upvaluing VDist3 makes it 7% faster.

ModuleName = "VDist3"
ModuleLoopCount = 100000

-- Operating on vectors in upvalues

local pos1 = Vector(Random()*1000, Random()*1000, Random()*1000)
local pos2 = Vector(Random()*1000, Random()*1000, Random()*1000)

function GlobalLuaVDist3OnUpvalues(loop)
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for i=1, loop do
        local dx, dy, dz = pos1[1] - pos2[1]
            , pos1[2] - pos2[2]
            , pos1[3] - pos2[3]
        local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function GlobalEngineVDist3OnUpvalues(loop)
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for i=1, loop do
        local dist = VDist3(pos1, pos2)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function UpvaluedLuaVDist3OnUpvalues(loop)
    -- upvalue
    local MathSqrt = math.sqrt

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for i=1, loop do
        local dx, dy, dz = pos1[1] - pos2[1]
            , pos1[2] - pos2[2]
            , pos1[3] - pos2[3]
        local dist = MathSqrt(dx*dx + dy*dy + dz*dz)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function UpvaluedEngineVDist3OnUpvalues(loop)
    -- upvalue
    local VDist3 = VDist3

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for i=1, loop do
        local dist = VDist3(pos1, pos2)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

-- Operating on local vectors

function GlobalLuaVDist3OnLocals(loop)
    local pos1 = Vector(Random()*1000, Random()*1000, Random()*1000)
    local pos2 = Vector(Random()*1000, Random()*1000, Random()*1000)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for i=1, loop do
        local dx, dy, dz = pos1[1] - pos2[1]
            , pos1[2] - pos2[2]
            , pos1[3] - pos2[3]
        local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function GlobalEngineVDist3OnLocals(loop)
    local pos1 = Vector(Random()*1000, Random()*1000, Random()*1000)
    local pos2 = Vector(Random()*1000, Random()*1000, Random()*1000)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for i=1, loop do
        local dist = VDist3(pos1, pos2)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function UpvaluedLuaVDist3OnLocals(loop)
    local pos1 = Vector(Random()*1000, Random()*1000, Random()*1000)
    local pos2 = Vector(Random()*1000, Random()*1000, Random()*1000)

    -- upvalue
    local MathSqrt = math.sqrt

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for i=1, loop do
        local dx, dy, dz = pos1[1] - pos2[1]
            , pos1[2] - pos2[2]
            , pos1[3] - pos2[3]
        local dist = MathSqrt(dx*dx + dy*dy + dz*dz)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function UpvaluedEngineVDist3OnLocals(loop)
    local pos1 = Vector(Random()*1000, Random()*1000, Random()*1000)
    local pos2 = Vector(Random()*1000, Random()*1000, Random()*1000)

    -- upvalue
    local VDist3 = VDist3

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for i=1, loop do
        local dist = VDist3(pos1, pos2)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

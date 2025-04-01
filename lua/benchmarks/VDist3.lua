-- GlobalEngineVDist3OnGlobals:         0.064697265625
-- GlobalEngineVDist3OnLocals:          0.06640625
-- GlobalLuaVDist3OnGlobals:            0.072998046875
-- GlobalLuaVDist3OnLocals:             0.067138671875
-- UpvaluedEngineVDist3OnGlobals:       0.059814453125
-- UpvaluedEngineVDist3OnLocals:        0.059814453125
-- UpvaluedLuaVDist3OnGlobals:          0.068359375
-- UpvaluedLuaVDist3OnLocals:           0.0615234375        # Sometimes this can be faster than `UpvaluedEngineVDist3OnLocals` in this benchmark but not often enough

-- Conclusion: Using VDist3 instead of calculating in Lua is faster due to an engine patch: https://github.com/FAForever/FA-Binary-Patches/pull/54
-- Make sure to upvalue VDist3 for a significant performance boost

ModuleName = "VDist3"

local pos1 = Vector(Random()*1000, Random()*1000, Random()*1000)
local pos2 = Vector(Random()*1000, Random()*1000, Random()*1000)

function GlobalLuaVDist3OnGlobals(loop)
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

function GlobalEngineVDist3OnGlobals(loop)
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for i=1, loop do
        local dist = VDist3(pos1, pos2)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function UpvaluedLuaVDist3OnGlobals(loop)
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

function UpvaluedEngineVDist3OnGlobals(loop)
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

    for i=1, outerLoop do
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

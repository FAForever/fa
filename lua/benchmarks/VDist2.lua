-- UpvaluedEngineVDist2OnLocals:        0.043102264404297
-- UpvaluedEngineVDist2SqOnLocals:      0.040153503417969
-- UpvaluedLuaVDist2OnLocals:           0.029483795166016
-- UpvaluedLuaVDist2SqOnLocals:         0.014518737792969

-- Conclusion: Lua is much faster, especially when skipping the square root (useful in distance comparisons).

ModuleName = "VDist2"

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

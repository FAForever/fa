
-- AbsGlobal:               440 ms
-- AbsLocal:                263 ms
-- AbsLocalPerIteration:    476 ms
-- AbsUpvalue:              277 ms

-- CeilGlobal:              1747 ms
-- CeilLocal:               1563 ms
-- CeilLocalPerIteration:   1781 ms
-- CeilUpvalue:             1572 ms

-- Conclusion: we should uplift these functions whenever possible.


ModuleName = "Generic math"
BenchmarkData = {
    AbsGlobal = "Global math.abs",
    AbsUpvalue = "Upvalued math.abs",
    AbsLocal = "Local math.abs",
    AbsLocalPerIteration = "Local math.abs per iteration",
    CeilGlobal = "Global math.ceil",
    CeilUpvalue = "Upvalued math.ceil",
    CeilLocal = "Local math.ceil",
    CeilLocalPerIteration = "Local math.ceil per iteration",
}

function AbsGlobal(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    for _ = 1, loop do
        math.abs(a)
    end

    local final = timer()
    return final - start
end

local MathAbs = math.abs

function AbsUpvalue(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    for _ = 1, loop do
        MathAbs(a)
    end

    local final = timer()
    return final - start
end

function AbsLocal(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    local MathAbs = math.abs
    for _ = 1, loop do
        MathAbs(a)
    end

    local final = timer()
    return final - start
end

function AbsLocalPerIteration(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    for _ = 1, loop do
        local MathAbs = math.abs
        MathAbs(a)
    end

    local final = timer()
    return final - start
end

function CeilGlobal(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    for _ = 1, loop do
        math.ceil(a)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

local MathCeil = math.ceil

function CeilUpvalue(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    for _ = 1, loop do
        MathCeil(a)
    end

    local final = timer()
    return final - start
end

function CeilLocal(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    local MathCeil = math.ceil
    for _ = 1, loop do
        MathCeil(a)
    end

    local final = timer()
    return final - start
end

function CeilLocalPerIteration(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    for _ = 1, loop do
        local MathCeil = math.ceil
        MathCeil(a)
    end

    local final = timer()
    return final - start
end

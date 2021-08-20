
-- AbsGlobal:               440 ms
-- AbsLocal:                263 ms
-- AbsLocalPerIteration:    476 ms
-- AbsUpvalue:              277 ms

-- CeilGlobal:              1747 ms
-- CeilLocal:               1563 ms
-- CeilLocalPerIteration:   1781 ms
-- CeilUpvalue:             1572 ms

-- Conclusion: we should uplift these functions whenever possible.

local outerLoop = 10000000

function AbsGlobal()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local a = 1.1
    for k = 1, outerLoop do
        a = math.abs(a)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

local MathAbs = math.abs

function AbsUpvalue()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local a = 1.1
    for k = 1, outerLoop do
        a = MathAbs(a)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function AbsLocal()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local MathAbs = math.abs

    local a = 1.1
    for k = 1, outerLoop do
        a = MathAbs(a)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function AbsLocalPerIteration()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local a = 1.1
    for k = 1, outerLoop do
        local MathAbs = math.abs
        a = MathAbs(a)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function CeilGlobal()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local a = 1.1
    for k = 1, outerLoop do
        a = math.ceil(a)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

local MathCeil = math.ceil

function CeilUpvalue()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local a = 1.1
    for k = 1, outerLoop do
        a = MathCeil(a)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function CeilLocal()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local MathCeil = math.ceil

    local a = 1.1
    for k = 1, outerLoop do
        a = MathCeil(a)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function CeilLocalPerIteration()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local a = 1.1
    for k = 1, outerLoop do
        local MathCeil = math.ceil
        a = MathCeil(a)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end


-- CosGlobal:               41.25 ms
-- CosUpvalue:              38.35 ms
-- CosLocal:                37.35 ms
-- CosLocalPerIteration:    39.50 ms

-- SinGlobal:               39.30 ms
-- SinUpvalue:              38.33 ms
-- SinLocal:                38.52 ms
-- SinLocalPerIteration:    40.28 ms

-- TanGlobal:               38.88 ms
-- TanUpvalue:              37.55 ms
-- TanLocal:                37.59 ms
-- TanLocalPerIteration:    40.03 ms

-- Conclusion: these functions are very cheap to use and are likely a lookup table
-- on the C-side.

function SinGlobal()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local a = 1.1
    for k = 1, 100000 do
        a = math.sin(k)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

local MathSin = math.sin

function SinUpvalue()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local a = 1.1
    for k = 1, 100000 do
        a = MathSin(k)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function SinLocal()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local MathSin = math.sin

    local a = 1.1
    for k = 1, 100000 do
        a = MathSin(k)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function SinLocalPerIteration()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local a = 1.1
    for k = 1, 100000 do
        local MathSin = math.sin
        a = MathSin(k)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function CosGlobal()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local a = 1.1
    for k = 1, 100000 do
        a = math.cos(k)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

local MathCos = math.cos

function CosUpvalue()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local a = 1.1
    for k = 1, 100000 do
        a = MathCos(k)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function CosLocal()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local MathCos = math.cos

    local a = 1.1
    for k = 1, 100000 do
        a = MathCos(k)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function CosLocalPerIteration()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local a = 1.1
    for k = 1, 100000 do
        local MathCos = math.cos
        a = MathCos(k)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function TanGlobal()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local a = 1.1
    for k = 1, 100000 do
        a = math.tan(k)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

local MathTan = math.tan

function TanUpvalue()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local a = 1.1
    for k = 1, 100000 do
        a = MathTan(k)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function TanLocal()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local MathTan = math.tan

    local a = 1.1
    for k = 1, 100000 do
        a = MathTan(k)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function TanLocalPerIteration()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local a = 1.1
    for k = 1, 100000 do
        local MathTan = math.tan
        a = MathTan(k)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end


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


ModuleName = "Math Trigonometry"
BenchmarkData = {
    SinGlobal = "Global math.sin",
    SinUpvalue = "Upvalued math.sin",
    SinLocal = "Local math.sin",
    SinLocalPerIteration = "Local math.sin per iteration",
    CosGlobal = "Global math.cos",
    CosUpvalue = "Upvalued math.cos",
    CosLocal = "Local math.cos",
    CosLocalPerIteration = "Local math.cos per iteration",
    TanGlobal = "Global math.tan",
    TanUpvalue = "Upvalued math.tan",
    TanLocal = "Local math.tan",
    TanLocalPerIteration = "Local math.tan per iteration",
}


function SinGlobal(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    for _ = 1, loop do
        math.sin(a)
    end

    local final = timer()
    return final - start
end

local MathSin = math.sin

function SinUpvalue(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    for _ = 1, loop do
        MathSin(a)
    end

    local final = timer()
    return final - start
end

function SinLocal(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    local MathSin = math.sin
    for _ = 1, loop do
        MathSin(_)
    end

    local final = timer()
    return final - start
end

function SinLocalPerIteration(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    for _ = 1, loop do
        local MathSin = math.sin
        MathSin(a)
    end

    local final = timer()
    return final - start
end

function CosGlobal(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    for _ = 1, loop do
        math.cos(a)
    end

    local final = timer()
    return final - start
end

local MathCos = math.cos

function CosUpvalue(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    for _ = 1, loop do
        MathCos(a)
    end

    local final = timer()
    return final - start
end

function CosLocal(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    local MathCos = math.cos
    for _ = 1, loop do
        MathCos(a)
    end

    local final = timer()
    return final - start
end

function CosLocalPerIteration(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    for k = 1, loop do
        local MathCos = math.cos
        MathCos(a)
    end

    local final = timer()
    return final - start
end

function TanGlobal(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    for _ = 1, loop do
        math.tan(a)
    end

    local final = timer()
    return final - start
end

local MathTan = math.tan

function TanUpvalue(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    for _ = 1, loop do
        MathTan(a)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function TanLocal(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    local MathTan = math.tan
    for _ = 1, loop do
        MathTan(a)
    end

    local final = timer()
    return final - start
end

function TanLocalPerIteration(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    for _ = 1, loop do
        local MathTan = math.tan
        MathTan(a)
    end

    local final = timer()
    return final - start
end

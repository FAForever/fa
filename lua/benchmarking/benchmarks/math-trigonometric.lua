
-- core findings:
-- These functions are _cheap_, very _cheap_. I suspect they use a lookup table on the C side.

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.00720

function SinGlobal()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local a = 1.1
    for k = 1, 100000 do
        a = math.sin(k)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.00573

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

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.00585

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

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.00732

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

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.00708

function CosGlobal()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local a = 1.1
    for k = 1, 100000 do
        a = math.cos(k)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.00585

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

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.00573

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

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.00720

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

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.00659

function TanGlobal()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local a = 1.1
    for k = 1, 100000 do
        a = math.tan(k)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.00524

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

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.00524

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

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.00683

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

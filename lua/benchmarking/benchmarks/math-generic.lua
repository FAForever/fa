
-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.00469

function AbsGlobal()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local a = 1.1
    for k = 1, 100000 do
        a = math.abs(a, 1.1)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.00274

local MathAbs = math.abs

function AbsUpvalue()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local a = 1.1
    for k = 1, 100000 do
        a = MathAbs(a, 1.1)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.00271

function AbsLocal()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local MathAbs = math.abs

    local a = 1.1
    for k = 1, 100000 do
        a = MathAbs(a, 1.1)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.00488

function AbsLocalPerIteration()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local a = 1.1
    for k = 1, 100000 do
        local MathAbs = math.abs
        a = MathAbs(a, 1.1)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.0171

function CeilGlobal()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local a = 1.1
    for k = 1, 100000 do
        a = math.ceil(a)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.0156

local MathCeil = math.ceil

function CeilUpvalue()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local a = 1.1
    for k = 1, 100000 do
        a = MathCeil(a)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.0155

function CeilLocal()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local MathCeil = math.ceil

    local a = 1.1
    for k = 1, 100000 do
        a = MathCeil(a)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.0173

function CeilLocalPerIteration()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local a = 1.1
    for k = 1, 100000 do
        local MathCeil = math.ceil
        a = MathCeil(a)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

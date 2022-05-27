
-- Call1:   0.2828 ms
-- Call2:   0.0532 ms
-- Call3:   0.0856 ms

-- Inline1: 0.2250 ms
-- Inline2: 0.0107 ms
-- Inline3: 0.0644 ms

-- Conclusion: there is an overhead for performing a function call and this matters when the logic
-- that is performed in the function is small. Call1 / Inline1 are from /lua/defaultexplosions.lua and
-- call3 / inline3 are from /lua/utilities.lua.

local outerLoop = 1000000

function Call1()

    local function GetUnitSizes(unit)
        local bp = unit:GetBlueprint()
        return bp.SizeX or 0, bp.SizeY or 0, bp.SizeZ or 0
    end
    
    local function GetUnitVolume(unit)
        local x, y, z = GetUnitSizes(unit)
        return x * y * z
    end

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local size = 0
    for k = 1, outerLoop do 
        size = GetUnitVolume(unit)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- remove dummy unit
    unit:Destroy()

    return final - start
end

function Inline1()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local size = false
    for k = 1, outerLoop do 
        local blueprint = unit:GetBlueprint()
        local sx, sy, sz = blueprint.SizeX or 0, blueprint.SizeY or 0, blueprint.SizeZ or 0
        size = sx * sy * sz
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- remove dummy unit
    unit:Destroy()

    return final - start
end

function Call2()

    local function Square(a)
        return a * a
    end
    
    local function AddOneThenSquare(a)
        return Square(a + 1)
    end

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local size = 0
    for k = 1, outerLoop do 
        size = AddOneThenSquare(k)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function Inline2()

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local size = false
    for k = 1, outerLoop do 
        size = (k + 1) * (k + 1)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end


function Call3()


    local function GetRandomFloat(nmin, nmax)
        return Random() * (nmax - nmin) + nmin
    end

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local size = 0
    for k = 1, outerLoop do 
        size = GetRandomFloat(10, k + 20)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function Inline3()

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local size = false
    for k = 1, outerLoop do 
        size = Random() * (k + 20 - 10) + 10
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end
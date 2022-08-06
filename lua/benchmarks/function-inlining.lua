
-- Call1:   0.2828 ms
-- Call2:   0.0532 ms
-- Call3:   0.0856 ms

-- Inline1: 0.2250 ms
-- Inline2: 0.0107 ms
-- Inline3: 0.0644 ms

-- Conclusion: there is an overhead for performing a function call and this matters when the logic
-- that is performed in the function is small. Call1 / Inline1 are from /lua/defaultexplosions.lua and
-- call3 / inline3 are from /lua/utilities.lua.

ModuleName = "Function Inlining"
BenchmarkData = {
    Call1 = "Call 1",
    Call2 = "Call 2",
    Call3 = "Call 3",
    Inline1 = "Inline 1",
    Inline2 = "Inline 2",
    Inline3 = "Inline 3",
}

function Call1(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

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
    local size
    local start = timer()

    for _ = 1, loop do
        size = GetUnitVolume(unit)
    end

    local final = timer()
    -- remove dummy unit
    unit:Destroy()
    return final - start
end

function Inline1(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    local size
    local start = timer()

    for _ = 1, loop do
        local blueprint = unit:GetBlueprint()
        local sx, sy, sz = blueprint.SizeX or 0, blueprint.SizeY or 0, blueprint.SizeZ or 0
        size = sx * sy * sz
    end

    local final = timer()
    -- remove dummy unit
    unit:Destroy()
    return final - start
end

function Call2(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local function Square(a)
        return a * a
    end
    local function AddOneThenSquare(a)
        return Square(a + 1)
    end

    local size
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, loop do
        size = AddOneThenSquare(k)
    end

    local final = timer()
    return final - start
end

function Inline2(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local size
    local start = timer()

    for k = 1, loop do
        size = (k + 1) * (k + 1)
    end

    local final = timer()
    return final - start
end


function Call3(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local function GetRandomFloat(nmin, nmax)
        return Random() * (nmax - nmin) + nmin
    end

    local size
    local start = timer()

    for k = 1, loop do
        size = GetRandomFloat(10, k + 20)
    end

    local final = timer()
    return final - start
end

function Inline3(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local size
    local start = timer()

    for k = 1, loop do
        size = Random() * (k + 20 - 10) + 10
    end

    local final = timer()
    return final - start
end
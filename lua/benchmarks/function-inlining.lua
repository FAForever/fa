
-- Results with parameters 10000:
--
-- |-------------------------|---------|---------|------------|-----------|---------|-------|-----------|---------|---------|-------|
-- | Name                    | Samples | Mean ms | +/- 95% ms | +/- 95% % |  Dev ms |  CV % | Median ms |  Min ms |  Max ms |  Skew |
-- |-------------------------|---------|---------|------------|-----------|---------|-------|-----------|---------|---------|-------|
-- | "Call 1"                |      28 | 1.99590 |    0.00880 |      0.44 | 0.02268 |  1.14 |   1.99509 | 1.95313 | 2.04468 |  0.41 |
-- | "Call 2"                |      27 | 0.38232 |    0.00174 |      0.46 | 0.00440 |  1.15 |   0.38147 | 0.37384 | 0.38910 |  0.01 |
-- | "Call 3"                |      29 | 0.60141 |    0.00280 |      0.47 | 0.00737 |  1.23 |   0.60272 | 0.58746 | 0.61798 | -0.13 |
-- | "Inline 1"              |      28 | 1.59509 |    0.00809 |      0.51 | 0.02086 |  1.31 |   1.59073 | 1.55640 | 1.64795 |  0.41 |
-- | "Inline 2"              |      28 | 0.08610 |    0.00177 |      2.06 | 0.00458 |  5.31 |   0.08392 | 0.07629 | 0.09155 | -0.16 |
-- | "Inline 3"              |      25 | 0.39764 |    0.00229 |      0.57 | 0.00554 |  1.39 |   0.39673 | 0.38910 | 0.40436 | -0.17 |
-- |-------------------------|---------|---------|------------|-----------|---------|-------|-----------|---------|---------|-------|
-- | "Baseline, 1 parameter" |     184 | 0.03786 |    0.00068 |      1.78 | 0.00468 | 12.35 |   0.03815 | 0.03052 | 0.06866 |  2.00 |
-- |-------------------------|---------|---------|------------|-----------|---------|-------|-----------|---------|---------|-------|

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
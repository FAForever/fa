
-- Results with loop count 200000:
--
-- |-------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|-------|
-- | Name                    | Samples | Mean ms | +/- 95% ms | +/- 95% % | Dev ms | CV % | Median ms |  Min ms |  Max ms |  Skew |
-- |-------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|-------|
-- | "Call 1"                |      29 | 40.6357 |     0.0746 |      0.18 | 0.1963 | 0.48 |   40.6342 | 40.3137 | 41.0004 |  0.12 |
-- | "Call 2"                |      32 |  7.9365 |     0.0250 |      0.31 | 0.0698 | 0.88 |    7.9346 |  7.8125 |  8.0719 |  0.14 |
-- | "Call 3"                |      29 | 12.2881 |     0.0429 |      0.35 | 0.1129 | 0.92 |   12.2681 | 12.1155 | 12.5580 |  0.34 |
-- | "Inline 1"              |      28 | 32.1890 |     0.0809 |      0.25 | 0.2087 | 0.65 |   32.2113 | 31.8298 | 32.5928 |  0.10 |
-- | "Inline 2"              |      30 |  1.7019 |     0.0191 |      1.12 | 0.0513 | 3.01 |    1.7014 |  1.6174 |  1.8158 |  0.38 |
-- | "Inline 3"              |      26 | 12.7745 |     0.0220 |      0.17 | 0.0544 | 0.43 |   12.7869 | 12.6495 | 12.8784 | -0.26 |
-- |-------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|-------|
-- | "Baseline, 1 parameter" |     165 |  0.7444 |     0.0034 |      0.46 | 0.0225 | 3.02 |    0.7477 |  0.7019 |  0.7935 |  0.34 |
-- |-------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|-------|

-- Conclusion: there is an overhead for performing a function call and this matters when the logic
-- that is performed in the function is small. Call1 / Inline1 are from /lua/defaultexplosions.lua and
-- call3 / inline3 are from /lua/utilities.lua.
--
-- Inlining makes Call1 1.26x faster and Call2 4.7x faster. Call3 and Inline3 are within 4% of each
-- other, since the `Random` call in both takes most of the time.

ModuleName = "Function Inlining"
ModuleLoopCount = 200000
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
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 1)
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
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 1)
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

-- Results with loop count 200000:
--
-- |-------------------------|---------|---------|------------|-----------|--------|-------|-----------|---------|---------|------|
-- | Name                    | Samples | Mean ms | +/- 95% ms | +/- 95% % | Dev ms |  CV % | Median ms |  Min ms |  Max ms | Skew |
-- |-------------------------|---------|---------|------------|-----------|--------|-------|-----------|---------|---------|------|
-- | "Depth 1"               |      32 |  6.9046 |     0.0700 |      1.01 | 0.1959 |  2.84 |    6.9580 |  6.5918 |  7.3242 | 0.34 |
-- | "Depth 2"               |      32 |  7.9803 |     0.0812 |      1.02 | 0.2273 |  2.85 |    7.9346 |  7.5684 |  8.4229 | 0.45 |
-- | "Depth 3"               |      29 |  9.2353 |     0.0516 |      0.56 | 0.1356 |  1.47 |    9.2773 |  9.0332 |  9.5215 | 0.38 |
-- | "Depth 4"               |      29 | 10.5696 |     0.0663 |      0.63 | 0.1742 |  1.65 |   10.6201 | 10.2539 | 10.9863 | 0.08 |
-- | "Depth 5"               |      26 | 11.9300 |     0.0719 |      0.60 | 0.1779 |  1.49 |   11.9019 | 11.5967 | 12.3291 | 0.30 |
-- | "Depth 6"               |      25 | 13.9502 |     0.0867 |      0.62 | 0.2100 |  1.51 |   13.9160 | 13.6719 | 14.4043 | 0.71 |
-- | "Depth 6 Functions"     |      29 | 36.8526 |     0.1747 |      0.47 | 0.4595 |  1.25 |   36.8652 | 36.2549 | 37.8418 | 0.64 |
-- | "Army from Field"       |      29 |  1.9110 |     0.0285 |      1.49 | 0.0749 |  3.92 |    1.9531 |  1.8311 |  2.0752 | 0.31 |
-- | "Army from Meta"        |      19 |  1.9531 |     0.0000 |      0.00 | 0.0000 |  0.00 |    1.9531 |  1.9531 |  1.9531 | 0.00 |
-- | "ForkThread from Field" |      30 |  1.9165 |     0.0320 |      1.67 | 0.0857 |  4.47 |    1.9531 |  1.8311 |  2.0752 | 0.45 |
-- | "ForkThread from Meta"  |      29 |  3.0181 |     0.0349 |      1.16 | 0.0917 |  3.04 |    3.0518 |  2.9297 |  3.1738 | 0.46 |
-- |-------------------------|---------|---------|------------|-----------|--------|-------|-----------|---------|---------|------|
-- | "Baseline, 1 parameter" |     334 |  0.7598 |     0.0084 |      1.10 | 0.0781 | 10.27 |    0.7324 |  0.6104 |  1.4648 | 3.61 |
-- |-------------------------|---------|---------|------------|-----------|--------|-------|-----------|---------|---------|------|
--
-- The timer was too coarse for these, so they are less accurate: "Army from Field", "Army from
-- Meta", "ForkThread from Field".

-- Each metatable level adds about 7 ns to finding the value. With `__index` functions instead of
-- tables, depth 6 is 2.6x slower. On a unit, reading `ForkThread` from its class takes 1.6x as long
-- as reading `Army`, which is found sooner.

-- A few notes:
-- - These tests assume that the value we're looking for is in the last metatable. If the value is found earlier then it is faster.
-- - The table checks if its metatable has a __index set, if not it just returns nil.
-- - The __index can be a table or a function. Referencing a table directly is significantly faster.
-- - A lot of the values we cache in functions like unit.OnCreate(...) live in the most upper meta table and are very fast.
-- - Values that do not live there are slower. As an example: unit.Weapons. Caching improves performance to access patterns.

-- I think this optimisation is most valuable by caching values defined in the meta class directly during OnCreate. This should
-- only be done for values that are accessed often as caching involves cycles too. As an example: values that are only used once
-- are not worth caching. Instead, you may want to reduce the hierarchy.

ModuleName = "Metatables"
ModuleLoopCount = 200000
BenchmarkData = {
    Depth1 = "Depth 1",
    Depth2 = "Depth 2",
    Depth3 = "Depth 3",
    Depth4 = "Depth 4",
    Depth5 = "Depth 5",
    Depth6 = "Depth 6",
    Depth6Functions = "Depth 6 Functions",
    PracticalTestArmyMeta = "Army from Meta",
    PracticalTestArmyCached = "Army from Field",
    PracticalTestWeaponsMeta = "ForkThread from Meta",
    PracticalTestWeaponsCached = "ForkThread from Field",
}

local n1 = {}
local n2 = {}

function Depth1(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local t1 = { key = "value" }

    local data
    local a = 1
    local start = timer()

    for _ = 1, loop do
        data = t1.key
        -- add some random table operations
        data = n1.fake
        data = n2.fake
        n1.y = a - 1
        n2.y = a
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function Depth2(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local t2 = { key = "value", }
    t2.__index = t2
    local t1 = { bob = "noise" }
    setmetatable(t1, t2)

    local data
    local a = 1
    local start = timer()

    for _ = 1, loop do
        data = t1.key
        -- add some random table operations
        data = n1.fake
        data = n2.fake
        n1.y = a - 1
        n2.y = a
    end

    local final = timer()
    return final - start
end

function Depth3(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local t3 = { key = "value" }
    t3.__index = t3
    local t2 = { chalsea = "noise" }
    t2.__index = t2
    setmetatable(t2, t3)
    local t1 = { bob = "noise" }
    setmetatable(t1, t2)

    local data
    local a = 1
    local start = timer()

    for _ = 1, loop do
        data = t1.key
        -- add some random table operations
        data = n1.fake
        data = n2.fake
        n1.y = a - 1
        n2.y = a
    end

    local final = timer()
    return final - start
end

function Depth4(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local t4 = { key = "value" }
    t4.__index = t4
    local t3 = { roger = "rage" }
    t3.__index = t3
    setmetatable(t3, t4)
    local t2 = { chalsea = "noise" }
    t2.__index = t2
    setmetatable(t2, t3)
    local t1 = { bob = "noise" }
    setmetatable(t1, t2)

    local data
    local a = 1
    local start = timer()

    for _ = 1, loop do
        data = t1.key
        -- add some random table operations
        data = n1.fake
        data = n2.fake
        n1.y = a - 1
        n2.y = a
    end

    local final = timer()
    return final - start
end

function Depth5(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local t5 = { key = "value" }
    t5.__index = t5
    local t4 = { BLUEPRINTSHERE = "FORSALE" }
    t4.__index = t4
    setmetatable(t4, t5)
    local t3 = { roger = "rage" }
    t3.__index = t3
    setmetatable(t3, t4)
    local t2 = { chalsea = "noise" }
    t2.__index = t2
    setmetatable(t2, t3)
    local t1 = { bob = "noise" }
    setmetatable(t1, t2)

    local data
    local a = 1
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for _ = 1, loop do
        data = t1.key
        -- add some random table operations
        data = n1.fake
        data = n2.fake
        n1.y = a - 1
        n2.y = a
    end

    local final = timer()
    return final - start
end

function Depth6(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local t6 = { key = "value" }
    t6.__index = t6
    local t5 = { fkey = "fvalue" }
    t5.__index = t5
    setmetatable(t5, t6)
    local t4 = { pbr = "shaders" }
    t4.__index = t4
    setmetatable(t4, t5)
    local t3 = { whatAmIDoing = "withMyLife" }
    t3.__index = t3
    setmetatable(t3, t4)
    local t2 = { chalsea = "noise" }
    t2.__index = t2
    setmetatable(t2, t3)
    local t1 = { bob = "noise" }
    setmetatable(t1, t2)

    local data
    local a = 1
    local start = timer()

    for _ = 1, loop do
        data = t1.key
        -- add some random table operations
        data = n1.fake
        data = n2.fake
        n1.y = a - 1
        n2.y = a
    end

    local final = timer()
    return final - start
end

function Depth6Functions(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local t6 = { key = "value" }
    t6.__index = function(child, key)
        return t6[key]
    end

    local t5 = { fkey = "fvalue" }
    t5.__index = function(child, key)
        return t5[key]
    end
    setmetatable(t5, t6)

    local t4 = { pbr = "shaders" }
    t4.__index = function(child, key)
        return t4[key]
    end
    setmetatable(t4, t5)

    local t3 = { whatAmIDoing = "withMyLife" }
    t3.__index = function(child, key)
        return t3[key]
    end
    setmetatable(t3, t4)

    local t2 = { chalsea = "noise" }
    t2.__index = function(child, key)
        return t2[key]
    end
    setmetatable(t2, t3)

    local t1 = { bob = "noise" }
    setmetatable(t1, t2)

    local data
    local a = 1
    local start = timer()

    for _ = 1, loop do
        data = t1.key
        -- add some random table operations
        data = n1.fake
        data = n2.fake
        n1.y = a - 1
        n2.y = a
    end

    local final = timer()
    return final - start
end

function PracticalTestArmyMeta(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    local data
    local start = timer()

    for _ = 1, loop do
        data = unit.Army
    end

    local final = timer()
    unit:Destroy()
    return final - start
end

function PracticalTestArmyCached(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    unit.Army = unit.Army

    local data
    local start = timer()

    for _ = 1, loop do
        data = unit.Army
    end

    local final = timer()
    unit:Destroy()
    return final - start
end

function PracticalTestWeaponsMeta(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    local data
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for _ = 1, loop do
        data = unit.ForkThread
    end

    local final = timer()
    unit:Destroy()
    return final - start
end

function PracticalTestWeaponsCached(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    unit.ForkThread = unit.ForkThread

    local data
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for _ = 1, loop do
        data = unit.ForkThread
    end

    local final = timer()
    unit:Destroy()
    return final - start
end
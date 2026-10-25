
-- Results with parameters 10000:
--
-- |-------------------------|---------|---------|------------|-----------|---------|-------|-----------|---------|---------|-------|
-- | Name                    | Samples | Mean ms | +/- 95% ms | +/- 95% % |  Dev ms |  CV % | Median ms |  Min ms |  Max ms |  Skew |
-- |-------------------------|---------|---------|------------|-----------|---------|-------|-----------|---------|---------|-------|
-- | "Depth 1"               |      25 | 0.36865 |    0.00393 |      1.07 | 0.00953 |  2.58 |   0.36621 | 0.35095 | 0.38147 | -0.10 |
-- | "Depth 2"               |      29 | 0.43514 |    0.00964 |      2.21 | 0.02534 |  5.82 |   0.44250 | 0.39673 | 0.48828 |  0.13 |
-- | "Depth 3"               |      29 | 0.49354 |    0.00565 |      1.14 | 0.01486 |  3.01 |   0.48828 | 0.47302 | 0.51880 |  0.20 |
-- | "Depth 4"               |      28 | 0.55967 |    0.00625 |      1.12 | 0.01611 |  2.88 |   0.56458 | 0.53406 | 0.59509 |  0.09 |
-- | "Depth 5"               |      28 | 0.64141 |    0.00797 |      1.24 | 0.02055 |  3.20 |   0.64087 | 0.59509 | 0.68665 | -0.06 |
-- | "Depth 6"               |      30 | 0.69631 |    0.00709 |      1.02 | 0.01900 |  2.73 |   0.69427 | 0.65613 | 0.73242 |  0.07 |
-- | "Depth 6 Functions"     |      28 | 1.89372 |    0.00651 |      0.34 | 0.01679 |  0.89 |   1.89209 | 1.86157 | 1.93787 |  0.60 |
-- | "Army from Field"       |      29 | 0.10155 |    0.00446 |      4.39 | 0.01173 | 11.55 |   0.09155 | 0.09155 | 0.12207 |  0.63 |
-- | "Army from Meta"        |      30 | 0.09562 |    0.00256 |      2.68 | 0.00686 |  7.18 |   0.09155 | 0.09155 | 0.10681 |  1.00 |
-- | "ForkThread from Field" |      30 | 0.09664 |    0.00273 |      2.83 | 0.00732 |  7.57 |   0.09155 | 0.09155 | 0.10681 |  0.67 |
-- | "ForkThread from Meta"  |      30 | 0.15462 |    0.00326 |      2.11 | 0.00872 |  5.64 |   0.15259 | 0.13733 | 0.18311 |  1.10 |
-- |-------------------------|---------|---------|------------|-----------|---------|-------|-----------|---------|---------|-------|
-- | "Baseline, 1 parameter" |     327 | 0.03892 |    0.00089 |      2.29 | 0.00823 | 21.16 |   0.04578 | 0.03052 | 0.06104 |  0.21 |
-- |-------------------------|---------|---------|------------|-----------|---------|-------|-----------|---------|---------|-------|
--
-- These are too short for the timer, so they mostly show its step: "Army from Field", "Army from
-- Meta", "ForkThread from Field", "ForkThread from Meta".

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
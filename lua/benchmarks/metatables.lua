
-- Depth1:          ~200ms  (~33ms without noise)
-- Depth2:          ~250ms  (~85ms without noise)
-- Depth3:          ~270ms  (~100ms without noise)
-- Depth4:          ~320ms  (~150ms without noise)
-- Depth5:          ~350ms  (~190ms without noise)
-- Depth6:          ~390ms  (~230ms without noise)
-- Depth6Functions: ~1050ms (~870ms without noise)

-- PracticalTestArmyMeta: ~57ms
-- PracticalTestArmyCached: ~56ms
-- PracticalTestWeaponsMeta: ~56ms
-- PracticalTestWeaponsCached: ~93ms

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

function Depth2()
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    t2 = { key = "value", }
    t2.__index = t2
    t1 = { bob = "noise" }
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
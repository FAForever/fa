
-- EngineCall:  146 ms
-- LuaCall:     54 ms
-- CachedCall:  8.5 ms

-- Performing engine calls are expensive and should be prevented in critical code. Calling getters
-- or setters should also be prevented - it is better to just get the member variable directly instead.

local outerLoop = 1000000

function EngineCall()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local isDead = false
    for k = 1, outerLoop do 
        isDead = unit:BeenDestroyed()
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- remove dummy unit
    unit:Destroy()

    return final - start
end

function LuaCall()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local isDead = false
    for k = 1, outerLoop do 
        isDead = unit.IsDead()
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- remove dummy unit
    unit:Destroy()

    return final - start
end

function CachedCall()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local isDead = false
    for k = 1, outerLoop do 
        isDead = unit.Dead
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- remove dummy unit
    unit:Destroy()

    return final - start
end
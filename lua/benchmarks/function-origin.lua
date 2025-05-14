
-- EngineCall:  146 ms
-- LuaCall:     54 ms
-- CachedCall:  8.5 ms

-- Performing engine calls are expensive and should be prevented in critical code. Calling getters
-- or setters should also be prevented - it is better to just get the member variable directly instead.

ModuleName = "Function Origins"
BenchmarkData = {
    EngineCall = "Engine Call",
    LuaCall = "Lua Call",
    CachedCall = "Cached Call",
}

function EngineCall(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    local isDead
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for _ = 1, loop do
        isDead = unit:BeenDestroyed()
    end

    local final = timer()
    -- remove dummy unit
    unit:Destroy()
    return final - start
end

function LuaCall(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    local isDead
    local start = timer()

    for _ = 1, loop do
        isDead = unit.IsDead()
    end

    local final = timer()
    -- remove dummy unit
    unit:Destroy()
    return final - start
end

function CachedCall(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    local isDead
    local start = timer()

    for _ = 1, loop do
        isDead = unit.Dead
    end

    local final = timer()
    -- remove dummy unit
    unit:Destroy()
    return final - start
end
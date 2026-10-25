
-- Results with parameters 10000:
--
-- |-------------------------|---------|---------|------------|-----------|---------|------|-----------|---------|---------|-------|
-- | Name                    | Samples | Mean ms | +/- 95% ms | +/- 95% % |  Dev ms | CV % | Median ms |  Min ms |  Max ms |  Skew |
-- |-------------------------|---------|---------|------------|-----------|---------|------|-----------|---------|---------|-------|
-- | "Cached Call"           |      30 | 0.12868 |    0.00179 |      1.39 | 0.00480 | 3.73 |   0.12970 | 0.12207 | 0.13733 |  0.09 |
-- | "Engine Call"           |      25 | 1.06201 |    0.00273 |      0.26 | 0.00661 | 0.62 |   1.06049 | 1.05286 | 1.07574 |  0.00 |
-- | "Lua Call"              |      25 | 0.34424 |    0.00166 |      0.48 | 0.00401 | 1.17 |   0.34332 | 0.33569 | 0.35095 |  0.16 |
-- |-------------------------|---------|---------|------------|-----------|---------|------|-----------|---------|---------|-------|
-- | "Baseline, 1 parameter" |      92 | 0.03782 |    0.00077 |      2.04 | 0.00374 | 9.88 |   0.03815 | 0.03052 | 0.04578 | -0.11 |
-- |-------------------------|---------|---------|------------|-----------|---------|------|-----------|---------|---------|-------|

-- Performing engine calls are expensive and should be prevented in critical code. Calling getters
-- or setters should also be prevented - it is better to just get the member variable directly instead.

ModuleName = "Function Origins"
ModuleLoopCount = 200000
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
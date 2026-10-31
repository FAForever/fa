
-- Results with loop count 200000:
--
-- |-------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|------|
-- | Name                    | Samples | Mean ms | +/- 95% ms | +/- 95% % | Dev ms | CV % | Median ms |  Min ms |  Max ms | Skew |
-- |-------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|------|
-- | "Cached Call"           |      30 |  2.5955 |     0.0278 |      1.07 | 0.0745 | 2.87 |    2.5864 |  2.4872 |  2.7313 | 0.14 |
-- | "Engine Call"           |      29 | 21.8285 |     0.0784 |      0.36 | 0.2062 | 0.94 |   21.8353 | 21.4844 | 22.2778 | 0.36 |
-- | "Lua Call"              |      28 |  7.0572 |     0.0111 |      0.16 | 0.0286 | 0.41 |    7.0648 |  7.0038 |  7.1259 | 0.13 |
-- |-------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|------|
-- | "Baseline, 1 parameter" |      90 |  0.7584 |     0.0059 |      0.78 | 0.0283 | 3.74 |    0.7477 |  0.7172 |  0.8240 | 0.42 |
-- |-------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|------|

-- Performing engine calls are expensive and should be prevented in critical code. Calling getters
-- or setters should also be prevented - it is better to just get the member variable directly instead.
-- The engine call is 3.1x slower than the Lua function call. "Lua Call" called `IsDead` without
-- the unit when these results were taken, so it needs a rerun.

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
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 1)
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
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 1)
    local isDead
    local start = timer()

    for _ = 1, loop do
        isDead = unit:IsDead()
    end

    local final = timer()
    -- remove dummy unit
    unit:Destroy()
    return final - start
end

function CachedCall(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 1)
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

-- Results with loop count 10000, inner loop count 45:
--
-- |--------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|-------|
-- | Name                     | Samples | Mean ms | +/- 95% ms | +/- 95% % | Dev ms | CV % | Median ms |  Min ms |  Max ms |  Skew |
-- |--------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|-------|
-- | "Cached function"        |      28 |  60.281 |      0.171 |      0.28 |  0.441 | 0.73 |    60.175 |  59.631 |  61.264 |  0.44 |
-- | "Inline function"        |      28 | 452.957 |      1.956 |      0.43 |  5.044 | 1.11 |   453.302 | 442.719 | 463.436 |  0.25 |
-- |--------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|-------|
-- | "Baseline, 2 parameters" |      58 |   1.885 |      0.019 |      1.01 |  0.072 | 3.83 |     1.881 |   1.751 |   2.037 | -0.02 |
-- |--------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|-------|

-- The inline version is 7.5x slower than the cached one. The set operation cache in
-- `/lua/system/categories.lua` narrows that to 2.1x (54.95 against 113.59 ms in a run with the
-- cache), so these benchmarks put the engine's set operations back while they run.

-- The performance of the cached version is faster when there is more than one
-- inner loop, but typically (significantly) better than the inline version. 
-- Highly recommending to upvalue the categories computation in both class 
-- and table based files.

ModuleName = "Categories"
BenchmarkData = {
    Cached = "Cached function",
    Inline = "Inline function",
}

--- `/lua/system/categories.lua` caches the results of set operations, which turns the inline
--- benchmark into cache lookups. Puts the engine's set operations back, which the cached versions
--- keep as upvalues named after the operation.
---@return fun() restore puts the cached set operations back
local function UseEngineSetOperations()
    local meta = getmetatable(categories.ALLUNITS)
    local replaced = {}
    for _, event in {"__add", "__sub", "__mul"} do
        local fn = meta[event]
        local i = 1
        local name, value = debug.getupvalue(fn, i)
        while name do
            if name == string.sub(event, 3) then
                replaced[event] = fn
                meta[event] = value
                break
            end
            i = i + 1
            name, value = debug.getupvalue(fn, i)
        end
    end
    return function()
        for event, fn in replaced do
            meta[event] = fn
        end
    end
end

--- Runs a timed loop with the engine's set operations, and puts the cached ones back even when the
--- loop fails. The loop gets its parameters as arguments, so they stay locals inside it.
---@param loop fun(outerLoop: number, innerLoop: number, unit: Unit): number
---@param outerLoop number
---@param innerLoop number
---@return number
local function RunWithEngineSetOperations(loop, outerLoop, innerLoop)
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 1)
    local restore = UseEngineSetOperations()
    local ok, result = pcall(loop, outerLoop, innerLoop, unit)
    restore()
    unit:Destroy()
    if not ok then
        error(result, 0)
    end
    return result
end

---@param outerLoop number
---@param innerLoop number
---@param unit Unit
---@return number
local function CachedLoop(outerLoop, innerLoop, unit)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local start = timer()

    for _ = 1, outerLoop do
        local cached = (categories.AIR * categories.TECH3) + categories.EXPERIMENTAL
        for _ = 1, innerLoop do
            EntityCategoryContains(cached, unit)
        end
    end

    local final = timer()
    return final - start
end

---@param outerLoop number
---@param innerLoop number
---@param unit Unit
---@return number
local function InlineLoop(outerLoop, innerLoop, unit)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local start = timer()

    for _ = 1, outerLoop do
        for _ = 1, innerLoop do
            EntityCategoryContains((categories.AIR * categories.TECH3) + categories.EXPERIMENTAL, unit)
        end
    end

    local final = timer()
    return final - start
end

function Cached(outerLoop, innerLoop)
    return RunWithEngineSetOperations(CachedLoop, outerLoop, innerLoop)
end

function Inline(outerLoop, innerLoop)
    return RunWithEngineSetOperations(InlineLoop, outerLoop, innerLoop)
end

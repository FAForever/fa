
-- Cached: 21 ms
-- Inline: 130 ms

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

function Cached(outerLoop, innerLoop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    local restore = UseEngineSetOperations()
    local start = timer()

    for _ = 1, outerLoop do
        local cached = (categories.AIR * categories.TECH3) + categories.EXPERIMENTAL
        for _ = 1, innerLoop do
            EntityCategoryContains(cached, unit)
        end
    end

    local final = timer()
    restore()
    unit:Destroy()
    return final - start
end

function Inline(outerLoop, innerLoop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    local restore = UseEngineSetOperations()
    local start = timer()

    for _ = 1, outerLoop do 
        for _ = 1, innerLoop do 
            EntityCategoryContains((categories.AIR * categories.TECH3) + categories.EXPERIMENTAL, unit)
        end
    end

    local final = timer()
    restore()
    unit:Destroy()
    return final - start
end
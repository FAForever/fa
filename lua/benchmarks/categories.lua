
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

function Cached(outerLoop, innerLoop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    local start = timer()

    for _ = 1, outerLoop do
        local cached = (categories.AIR * categories.TECH3) + categories.EXPERIMENTAL
        for _ = 1, innerLoop do
            EntityCategoryContains(cached, unit)
        end
    end

    local final = timer()
    unit:Destroy()
    return final - start
end

function Inline(outerLoop, innerLoop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    local start = timer()

    for _ = 1, outerLoop do 
        for _ = 1, innerLoop do 
            EntityCategoryContains((categories.AIR * categories.TECH3) + categories.EXPERIMENTAL, unit)
        end
    end

    local final = timer()
    unit:Destroy()
    return final - start
end
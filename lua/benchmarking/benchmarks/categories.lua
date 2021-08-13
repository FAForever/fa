
-- Cached: 21 ms
-- Inline: 130 ms

-- The performance of the cached version is faster when there is more than one
-- inner loop, but typically (significantly) better than the inline version. 
-- Highly recommending to upvalue the categories computation in both class 
-- and table based files.

local outerLoop = 1000
local innerLoop = 100

function Cached()

    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, outerLoop do 
        local cached = (categories.AIR * categories.TECH3) + categories.EXPERIMENTAL
        for l = 1, innerLoop do 
            EntityCategoryContains(cached, unit)
        end
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    unit:Destroy()

    return final - start
end

function Inline()

    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, outerLoop do 
        for l = 1, innerLoop do 
            EntityCategoryContains((categories.AIR * categories.TECH3) + categories.EXPERIMENTAL, unit)
        end
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    unit:Destroy()

    return final - start
end
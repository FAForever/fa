
function Cached()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    local cached = (categories.AIR * categories.TECH3) + categories.EXPERIMENTAL
    local sum = 1
    for k = 1, 100000 do 
        EntityCategoryContains(cached, unit)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    unit:Destroy()

    return final - start
end

function Inline()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local sum = 1
    for k = 1, 100000 do 
        EntityCategoryContains((categories.AIR * categories.TECH3) + categories.EXPERIMENTAL, unit)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    unit:Destroy()

    return final - start
end
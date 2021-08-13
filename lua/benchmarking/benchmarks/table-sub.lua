
-- 0.001663
function BlueprintSubTables2()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    local blueprint = unit:GetBlueprint()
    unit:Destroy()

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local sum = 1
    for k = 1, 100000 do 
        sum = sum + blueprint.Defense.MaxHealth
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

-- 0.001113
function BlueprintSubTables1()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    local blueprint = unit:GetBlueprint()
    local test = { DefenseMaxHealth = blueprint.Defense.MaxHealth }
    unit:Destroy()

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local sum = 1
    for k = 1, 100000 do 
        sum = sum + test.DefenseMaxHealth
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

-- 0.001663
function BlueprintSubTables2()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    local blueprint = unit.Blueprint
    unit:Destroy()

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local sum = 1
    for k = 1, 100000 do 
        sum = sum + blueprint.Defense.AirThreatLevel
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

-- 0.001113
function BlueprintSubTables1()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    local blueprint = unit.Blueprint
    local test = { DefenseAirThreatLevel = blueprint.Defense.AirThreatLevel }
    unit:Destroy()

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local sum = 1
    for k = 1, 100000 do 
        sum = sum + test.DefenseAirThreatLevel
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end
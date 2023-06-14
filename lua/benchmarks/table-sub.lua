
-- BlueprintSubTables2: 1.663 ms
-- BlueprintSubTables2: 1.113 ms

-- Conclusion: preventing table operations (the '.') is quite the benefit in practice.

ModuleName = "Table Subscript"
BenchmarkData = {
    BlueprintSubTables2 = "Chained access",
    BlueprintSubTables1 = "Localized Access",
}


function BlueprintSubTables2(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local blueprint = unit:GetBlueprint()

    unit:Destroy()
    local a
    local start = timer()

    for _ = 1, loop do
        a = blueprint.Defense.MaxHealth
    end

    local final = timer()
    return final - start
end

function BlueprintSubTables1(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local blueprint = unit:GetBlueprint()

    unit:Destroy()
    local a
    local start = timer()

    local Defense = blueprint.Defense
    for _ = 1, loop do
        a = Defense.MaxHealth
    end

    local final = timer()
    return final - start
end
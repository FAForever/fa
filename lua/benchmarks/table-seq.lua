

ModuleName = "Table Sequence"
BenchmarkData = {
    TableTest1 = "Chained access",
    TableTest2 = "Localized Access",
}

function TableTest2(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local t = {
        unit1 = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0),
        unit2 = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0),
    }

    local start = timer()

    for _ = 1, loop do
        local unit1 = t.unit1
        local unit2 = t.unit2
        if unit1 and unit2 then
            unit1:GetPosition()
            unit2:GetPosition()
            unit1:GetPositionXYZ()
            unit2:GetPositionXYZ()
        end
    end

    local final = timer()
    t.unit1:Destroy()
    t.unit2:Destroy()
    return final - start
end

function TableTest1(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local t = {
        unit1 = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0),
        unit2 = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0),
    }

    local start = timer()

    for _ = 1, loop do
        if t.unit1 and t.unit2 then
            t.unit1:GetPosition()
            t.unit2:GetPosition()
            t.unit1:GetPositionXYZ()
            t.unit2:GetPositionXYZ()
        end
    end

    local final = timer()
    t.unit1:Destroy()
    t.unit2:Destroy()
    return final - start
end

-- EntriesBracketShort: 1.09 ms
-- EntriesBracketLong:  1.09 ms
-- EntriesDotShort:     1.09 ms
-- EntriesDotLong:      1.09 ms

-- Conclusion: there is no difference.


ModuleName = "Table Access"
BenchmarkData = {
    EntriesBracketShort = "Entry using bracket (short)",
    EntriesBracketLong = "Entry using bracket (long)",
    EntriesDotShort = "Entry using dot (short)",
    EntriesDotLong = "Entry using dot (long)",
    TableTest1 = "Chained entries",
    TableTest2 = "Localized entries",
}

function EntriesBracketShort(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local data = { a = 1 }

    local a
    local start = timer()

    for _ = 1, loop do
        a = data["a"]
    end

    local final = timer()
    return final - start
end

function EntriesBracketLong(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local data = { ThisIsASuperLongEntryAndDoesThatMatterOrNotBecauseManThisStuffIsLong = 1}

    local a
    local start = timer()

    for _ = 1, loop do
        a = data["ThisIsASuperLongEntryAndDoesThatMatterOrNotBecauseManThisStuffIsLong"]
    end

    local final = timer()
    return final - start
end

function EntriesDotShort(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local data = { a = 1 }

    local a
    local start = timer()

    for _ = 1, loop do
        a = data.a
    end

    local final = timer()
    return final - start
end

function EntriesDotLong(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local data = { ThisIsASuperLongEntryAndDoesThatMatterOrNotBecauseManThisStuffIsLong = 1}

    local a
    local start = timer()

    for _ = 1, loop do
        a = data.ThisIsASuperLongEntryAndDoesThatMatterOrNotBecauseManThisStuffIsLong
    end

    local final = timer()
    return final - start
end

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
        unit2 = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
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
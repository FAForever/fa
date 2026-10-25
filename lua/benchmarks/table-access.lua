
-- Results with parameters 10000:
--
-- |-------------------------------|---------|---------|------------|-----------|--------|-------|-----------|--------|--------|------|
-- | Name                          | Samples | Mean ms | +/- 95% ms | +/- 95% % | Dev ms |  CV % | Median ms | Min ms | Max ms | Skew |
-- |-------------------------------|---------|---------|------------|-----------|--------|-------|-----------|--------|--------|------|
-- | "Entry using bracket (long)"  |      30 |  0.0621 |     0.0021 |      3.35 | 0.0056 |  8.98 |    0.0610 | 0.0610 | 0.0916 | 4.94 |
-- | "Entry using bracket (short)" |      60 |  0.0636 |     0.0022 |      3.45 | 0.0085 | 13.38 |    0.0610 | 0.0610 | 0.0916 | 2.94 |
-- | "Entry using dot (long)"      |      60 |  0.0641 |     0.0028 |      4.35 | 0.0108 | 16.86 |    0.0610 | 0.0305 | 0.0916 | 1.40 |
-- | "Entry using dot (short)"     |      30 |  0.0621 |     0.0021 |      3.35 | 0.0056 |  8.98 |    0.0610 | 0.0610 | 0.0916 | 4.94 |
-- | "Chained entries"             |      30 |  5.0018 |     0.0170 |      0.34 | 0.0456 |  0.91 |    5.0049 | 4.9438 | 5.0964 | 0.46 |
-- | "Localized entries"           |      28 |  4.9667 |     0.0666 |      1.34 | 0.1718 |  3.46 |    4.9744 | 4.7913 | 5.4321 | 1.12 |
-- |-------------------------------|---------|---------|------------|-----------|--------|-------|-----------|--------|--------|------|
-- | "Baseline, 1 parameter"       |     244 |  0.0404 |     0.0018 |      4.44 | 0.0143 | 35.42 |    0.0305 | 0.0305 | 0.0610 | 0.75 |
-- |-------------------------------|---------|---------|------------|-----------|--------|-------|-----------|--------|--------|------|
--
-- These are too short for the timer, so they mostly show its step: "Entry using bracket (long)",
-- "Entry using bracket (short)", "Entry using dot (long)", "Entry using dot (short)".

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
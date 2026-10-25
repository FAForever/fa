
-- Results with loop count 500000:
--
-- |-------------------------------|---------|----------|------------|-----------|--------|------|-----------|----------|----------|------|
-- | Name                          | Samples |  Mean ms | +/- 95% ms | +/- 95% % | Dev ms | CV % | Median ms |   Min ms |   Max ms | Skew |
-- |-------------------------------|---------|----------|------------|-----------|--------|------|-----------|----------|----------|------|
-- | "Entry using bracket (long)"  |      32 |   2.9564 |     0.0241 |      0.82 | 0.0675 | 2.28 |    2.9297 |   2.8076 |   3.1738 | 1.19 |
-- | "Entry using bracket (short)" |      22 |   2.9297 |     0.0000 |      0.00 | 0.0000 | 0.00 |    2.9297 |   2.9297 |   2.9297 | 0.00 |
-- | "Entry using dot (long)"      |      28 |   2.9689 |     0.0259 |      0.87 | 0.0669 | 2.25 |    2.9297 |   2.8076 |   3.0518 | 0.05 |
-- | "Entry using dot (short)"     |      28 |   2.9733 |     0.0231 |      0.78 | 0.0596 | 2.00 |    2.9297 |   2.9297 |   3.0518 | 0.56 |
-- | "Chained entries"             |      26 | 248.0281 |     0.4064 |      0.16 | 1.0058 | 0.41 |  247.7417 | 246.5820 | 250.3662 | 0.62 |
-- | "Localized entries"           |      28 | 239.4714 |     0.4051 |      0.17 | 1.0446 | 0.44 |  239.0747 | 237.9150 | 241.4551 | 0.62 |
-- |-------------------------------|---------|----------|------------|-----------|--------|------|-----------|----------|----------|------|
-- | "Baseline, 1 parameter"       |     172 |   1.8580 |     0.0092 |      0.50 | 0.0616 | 3.32 |    1.8311 |   1.7090 |   1.9531 | 0.33 |
-- |-------------------------------|---------|----------|------------|-----------|--------|------|-----------|----------|----------|------|

-- Conclusion: there is no difference between the ways of writing an entry. Localizing the entries is
-- 3.5% faster, which is small here because the four engine calls take most of the time.


ModuleName = "Table Access"
ModuleLoopCount = 500000
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

-- Results with loop count 10000:
--
-- |-------------------------|---------|---------|------------|-----------|--------|-------|-----------|--------|--------|------|
-- | Name                    | Samples | Mean ms | +/- 95% ms | +/- 95% % | Dev ms |  CV % | Median ms | Min ms | Max ms | Skew |
-- |-------------------------|---------|---------|------------|-----------|--------|-------|-----------|--------|--------|------|
-- | "Chained access"        |      30 |  5.0140 |     0.0141 |      0.28 | 0.0377 |  0.75 |    5.0049 | 4.9438 | 5.0964 | 0.50 |
-- | "Localized Access"      |      27 |  4.8105 |     0.0076 |      0.16 | 0.0192 |  0.40 |    4.8218 | 4.7913 | 4.8523 | 0.42 |
-- |-------------------------|---------|---------|------------|-----------|--------|-------|-----------|--------|--------|------|
-- | "Baseline, 1 parameter" |      64 |  0.0410 |     0.0036 |      8.82 | 0.0146 | 35.63 |    0.0305 | 0.0305 | 0.0610 | 0.64 |
-- |-------------------------|---------|---------|------------|-----------|--------|-------|-----------|--------|--------|------|

-- Localizing the access is 4.1% faster.


ModuleName = "Table Sequence"
BenchmarkData = {
    TableTest1 = "Chained access",
    TableTest2 = "Localized Access",
}

function TableTest2(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local t = {
        unit1 = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 1),
        unit2 = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 1),
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
        unit1 = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 1),
        unit2 = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 1),
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
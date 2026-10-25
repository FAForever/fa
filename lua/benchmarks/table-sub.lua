
-- Results with loop count 500000:
--
-- |-------------------------|---------|---------|------------|-----------|--------|------|-----------|--------|--------|------|
-- | Name                    | Samples | Mean ms | +/- 95% ms | +/- 95% % | Dev ms | CV % | Median ms | Min ms | Max ms | Skew |
-- |-------------------------|---------|---------|------------|-----------|--------|------|-----------|--------|--------|------|
-- | "Localized Access"      |      32 |   2.937 |      0.019 |      0.65 |  0.053 | 1.81 |     2.930 |  2.808 |  3.052 | 0.34 |
-- | "Chained access"        |      32 |   4.772 |      0.026 |      0.54 |  0.072 | 1.50 |     4.761 |  4.639 |  5.005 | 0.92 |
-- |-------------------------|---------|---------|------------|-----------|--------|------|-----------|--------|--------|------|
-- | "Baseline, 1 parameter" |      58 |   1.861 |      0.016 |      0.87 |  0.062 | 3.32 |     1.831 |  1.709 |  1.953 | 0.34 |
-- |-------------------------|---------|---------|------------|-----------|--------|------|-----------|--------|--------|------|

-- Conclusion: preventing table operations (the '.') is quite the benefit in practice. The chained
-- access takes 1.6x as long, or 2.7x without the loop.

ModuleName = "Table Subscript"
ModuleLoopCount = 500000
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
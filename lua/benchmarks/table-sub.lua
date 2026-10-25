
-- Results with parameters 10000:
--
-- |-------------------------|---------|---------|------------|-----------|--------|-------|-----------|--------|--------|------|
-- | Name                    | Samples | Mean ms | +/- 95% ms | +/- 95% % | Dev ms |  CV % | Median ms | Min ms | Max ms | Skew |
-- |-------------------------|---------|---------|------------|-----------|--------|-------|-----------|--------|--------|------|
-- | "Localized Access"      |      60 |  0.0661 |     0.0033 |      4.99 | 0.0128 | 19.32 |    0.0610 | 0.0610 | 0.1221 | 2.40 |
-- | "Chained access"        |      59 |  0.1045 |     0.0040 |      3.79 | 0.0152 | 14.56 |    0.0916 | 0.0916 | 0.1221 | 0.30 |
-- |-------------------------|---------|---------|------------|-----------|--------|-------|-----------|--------|--------|------|
-- | "Baseline, 1 parameter" |     119 |  0.0395 |     0.0025 |      6.42 | 0.0140 | 35.36 |    0.0305 | 0.0305 | 0.0610 | 0.89 |
-- |-------------------------|---------|---------|------------|-----------|--------|-------|-----------|--------|--------|------|
--
-- These are too short for the timer, so they mostly show its step: "Localized Access", "Chained
-- access".

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
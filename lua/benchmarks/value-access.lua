-- Results with parameters 10000:
--
-- |-------------------------|---------|---------|------------|-----------|--------|-------|-----------|--------|--------|-------|
-- | Name                    | Samples | Mean ms | +/- 95% ms | +/- 95% % | Dev ms |  CV % | Median ms | Min ms | Max ms |  Skew |
-- |-------------------------|---------|---------|------------|-----------|--------|-------|-----------|--------|--------|-------|
-- | "Global access"         |      32 |  0.1516 |     0.0019 |      1.27 | 0.0054 |  3.56 |    0.1526 | 0.1221 | 0.1526 | -5.14 |
-- | "Global CFunc Access"   |      26 |  0.5916 |     0.0061 |      1.03 | 0.0151 |  2.56 |    0.5798 | 0.5798 | 0.6104 |  0.45 |
-- | "Local access"          |      60 |  0.0656 |     0.0032 |      4.86 | 0.0123 | 18.81 |    0.0610 | 0.0305 | 0.0916 |  1.12 |
-- | "Local CFunc Access"    |      25 |  0.5249 |     0.0073 |      1.39 | 0.0176 |  3.36 |    0.5188 | 0.4883 | 0.5493 | -0.00 |
-- | "Upvalue access"        |      90 |  0.0804 |     0.0034 |      4.19 | 0.0161 | 20.09 |    0.0916 | 0.0610 | 0.1221 | -0.09 |
-- | "Upvalued CFunc Access" |      28 |  0.5351 |     0.0075 |      1.41 | 0.0194 |  3.63 |    0.5188 | 0.5188 | 0.5798 |  0.70 |
-- |-------------------------|---------|---------|------------|-----------|--------|-------|-----------|--------|--------|-------|
-- | "Baseline, 1 parameter" |     269 |  0.0400 |     0.0017 |      4.23 | 0.0142 | 35.38 |    0.0305 | 0.0305 | 0.0610 |  0.81 |
-- |-------------------------|---------|---------|------------|-----------|--------|-------|-----------|--------|--------|-------|
--
-- These are too short for the timer, so they mostly show its step: "Global access", "Local access",
-- "Upvalue access".

-- Conclusion: It is faster to access values in any way through lua instead of using CFuncs.

ModuleName = "Value access"
BenchmarkData = {
    BrainGlobalAccess = "Global access",
    BrainUpvalueAccess = "Upvalue access",
    BrainLocalAccess = "Local access",
    BrainGlobalCFuncAccess = "Global CFunc Access",
    BrainUpvaluedCFuncAccess = "Upvalued CFunc Access",
    BrainLocalCFuncAccess = "Local CFunc Access",
}

function BrainGlobalAccess(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local a

    local start = timer()

    for _ = 1, loop do
        a = ArmyBrains[1]
    end

    local final = timer()
    return final - start
end

local ArmyBrains = ArmyBrains
function BrainUpvalueAccess(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local a

    local start = timer()

    for _ = 1, loop do
        a = ArmyBrains[1]
    end

    local final = timer()
    return final - start
end

function BrainLocalAccess(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local armyBrains = ArmyBrains

    local a

    local start = timer()

    for _ = 1, loop do
        a = armyBrains[1]
    end

    local final = timer()
    return final - start
end

function BrainGlobalCFuncAccess(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local a

    local start = timer()

    for _ = 1, loop do
        a = GetArmyBrain(1)
    end

    local final = timer()
    return final - start
end

local GetArmyBrain = GetArmyBrain
function BrainUpvaluedCFuncAccess(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local a

    local start = timer()

    for _ = 1, loop do
        a = GetArmyBrain(1)
    end

    local final = timer()
    return final - start
end

function BrainLocalCFuncAccess(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local getArmyBrain = GetArmyBrain

    local a

    local start = timer()

    for _ = 1, loop do
        a = getArmyBrain(1)
    end

    local final = timer()
    return final - start
end

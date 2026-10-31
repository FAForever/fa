-- Results with loop count 500000:
--
-- |-------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|------|
-- | Name                    | Samples | Mean ms | +/- 95% ms | +/- 95% % | Dev ms | CV % | Median ms |  Min ms |  Max ms | Skew |
-- |-------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|------|
-- | "Global access"         |      31 |  6.9186 |     0.0268 |      0.39 | 0.0732 | 1.06 |    6.9580 |  6.8359 |  7.0801 | 0.22 |
-- | "Global CFunc Access"   |      28 | 32.7497 |     0.3490 |      1.07 | 0.9000 | 2.75 |   32.5317 | 31.4941 | 34.6680 | 0.58 |
-- | "Local access"          |      29 |  2.9592 |     0.0237 |      0.80 | 0.0624 | 2.11 |    2.9297 |  2.8076 |  3.0518 | 0.34 |
-- | "Local CFunc Access"    |      26 | 28.8180 |     0.2026 |      0.70 | 0.5014 | 1.74 |   28.8086 | 28.1982 | 30.0293 | 0.65 |
-- | "Upvalue access"        |      30 |  3.7679 |     0.0392 |      1.04 | 0.1050 | 2.79 |    3.7842 |  3.6621 |  4.0283 | 0.56 |
-- | "Upvalued CFunc Access" |      27 | 29.7716 |     0.2969 |      1.00 | 0.7505 | 2.52 |   29.6631 | 28.6865 | 31.4941 | 0.38 |
-- |-------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|------|
-- | "Baseline, 1 parameter" |     170 |  1.8677 |     0.0100 |      0.53 | 0.0662 | 3.54 |    1.8311 |  1.7090 |  1.9531 | 0.06 |
-- |-------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|------|

-- Conclusion: It is faster to access values in any way through lua instead of using CFuncs. Reading a
-- value takes about 2 ns from a local, 4 ns from an upvalue and 10 ns from a global. Getting it from
-- an engine function takes 54 to 62 ns.

ModuleName = "Value access"
ModuleLoopCount = 500000
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

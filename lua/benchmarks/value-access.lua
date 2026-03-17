-- Global access: 0.122ms
-- Global CFunc Access: 6.35ms
-- Upvalue access: 0.078ms
-- Upvalued CFunc Access: 6.23ms
-- Local access: 0.061ms
-- Local CFunc Access: 6.29ms

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

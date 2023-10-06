
--- Compares (using `>`) the ratio of ((energy stored) / (total energy storage))
---@param aiBrain AIBrain | AIBrainEconomyComponent
---@param base AIBase
---@param ratio number # number between 0.0 and 1.0
function GreaterEnergyRatio(aiBrain, base, ratio)
    return aiBrain:GetEconomyStoredRatio('ENERGY') > ratio
end

--- Compares (using `<`) the ratio of ((energy stored) / (total energy storage))
---@param aiBrain AIBrain | AIBrainEconomyComponent
---@param base AIBase
---@param ratio number # number between 0.0 and 1.0
function LessEnergyRatio(aiBrain, base, ratio)
    return aiBrain:GetEconomyStoredRatio('ENERGY') < ratio
end

--- Compares (using `>`) the ratio of ((mass stored) / (total mass storage))
---@param aiBrain AIBrain | AIBrainEconomyComponent
---@param base AIBase
---@param ratio number # number between 0.0 and 1.0
function GreaterMassRatio(aiBrain, base, ratio)
    return aiBrain:GetEconomyStoredRatio('MASS') > ratio
end

--- Compares (using `<`) the ratio of ((mass stored) / (total mass storage))
---@param aiBrain AIBrain | AIBrainEconomyComponent
---@param base AIBase
---@param ratio number # number between 0.0 and 1.0
function LessMassRatio(aiBrain, base, ratio)
    return aiBrain:GetEconomyStoredRatio('MASS') < ratio
end

--- Compares (using `>`) the trend of the ratio of ((energy stored) / (total energy storage))
---@param aiBrain AIBrain | AIBrainEconomyComponent
---@param base AIBase
---@param ratio number # number between 0.0 and 1.0
function GreaterEnergyRatioTrend(aiBrain, base, ratio)
    return aiBrain.EconomyOverTimeCurrent.EnergyStoredRatioOverTime > ratio
end

--- Compares (using `<`) the ratio of ((energy stored) / (total energy storage))
---@param aiBrain AIBrain | AIBrainEconomyComponent
---@param base AIBase
---@param ratio number # number between 0.0 and 1.0
function LessEnergyRatioTrend(aiBrain, base, ratio)
    return aiBrain.EconomyOverTimeCurrent.EnergyStoredRatioOverTime < ratio
end

--- Compares (using `>`) the ratio of ((mass stored) / (total mass storage))
---@param aiBrain AIBrain | AIBrainEconomyComponent
---@param base AIBase
---@param ratio number # number between 0.0 and 1.0
function GreaterMassRatioTrend(aiBrain, base, ratio)
    return aiBrain.EconomyOverTimeCurrent.MassStoredRatioOverTime > ratio
end

--- Compares (using `<`) the ratio of ((mass stored) / (total mass storage))
---@param aiBrain AIBrain | AIBrainEconomyComponent
---@param base AIBase
---@param ratio number # number between 0.0 and 1.0
function LessMassRatioTrend(aiBrain, base, ratio)
    return aiBrain.EconomyOverTimeCurrent.MassStoredRatioOverTime < ratio
end
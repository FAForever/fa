
--******************************************************************************************************
--** Copyright (c) 2022  Willem 'Jip' Wijnia
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

--- Compares (using `>`) the ratio of ((energy stored) / (total energy storage))
---@param aiBrain AIBrain | AIBrainEconomyComponent
---@param base AIBase
---@param ratio number # number between 0.0 and 1.0
function GreaterEnergyRatio(aiBrain, base, platoon, ratio)
    return aiBrain:GetEconomyStoredRatio('ENERGY') > ratio
end

--- Compares (using `<`) the ratio of ((energy stored) / (total energy storage))
---@param aiBrain AIBrain | AIBrainEconomyComponent
---@param base AIBase
---@param ratio number # number between 0.0 and 1.0
function LessEnergyRatio(aiBrain, base, platoon, ratio)
    return aiBrain:GetEconomyStoredRatio('ENERGY') < ratio
end

--- Compares (using `>`) the ratio of ((mass stored) / (total mass storage))
---@param aiBrain AIBrain | AIBrainEconomyComponent
---@param base AIBase
---@param ratio number # number between 0.0 and 1.0
function GreaterMassRatio(aiBrain, base, platoon, ratio)
    return aiBrain:GetEconomyStoredRatio('MASS') > ratio
end

--- Compares (using `<`) the ratio of ((mass stored) / (total mass storage))
---@param aiBrain AIBrain | AIBrainEconomyComponent
---@param base AIBase
---@param ratio number # number between 0.0 and 1.0
function LessMassRatio(aiBrain, base, platoon, ratio)
    return aiBrain:GetEconomyStoredRatio('MASS') < ratio
end

--- Compares (using `>`) the trend of the ratio of ((energy stored) / (total energy storage))
---@param aiBrain AIBrain | AIBrainEconomyComponent
---@param base AIBase
---@param ratio number # number between 0.0 and 1.0
function GreaterEnergyRatioTrend(aiBrain, base, platoon, ratio)
    return aiBrain.EconomyOverTimeCurrent.EnergyStoredRatioOverTime > ratio
end

--- Compares (using `<`) the ratio of ((energy stored) / (total energy storage))
---@param aiBrain AIBrain | AIBrainEconomyComponent
---@param base AIBase
---@param ratio number # number between 0.0 and 1.0
function LessEnergyRatioTrend(aiBrain, base, platoon, ratio)
    return aiBrain.EconomyOverTimeCurrent.EnergyStoredRatioOverTime < ratio
end

--- Compares (using `>`) the ratio of ((mass stored) / (total mass storage))
---@param aiBrain AIBrain | AIBrainEconomyComponent
---@param base AIBase
---@param ratio number # number between 0.0 and 1.0
function GreaterMassRatioTrend(aiBrain, base, platoon, ratio)
    return aiBrain.EconomyOverTimeCurrent.MassStoredRatioOverTime > ratio
end

--- Compares (using `<`) the ratio of ((mass stored) / (total mass storage))
---@param aiBrain AIBrain | AIBrainEconomyComponent
---@param base AIBase
---@param ratio number # number between 0.0 and 1.0
function LessMassRatioTrend(aiBrain, base, platoon, ratio)
    return aiBrain.EconomyOverTimeCurrent.MassStoredRatioOverTime < ratio
end
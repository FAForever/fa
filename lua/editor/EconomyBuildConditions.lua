--****************************************************************************
--**
--**  File     :  /lua/editor/EconomyBuildConditions.lua
--**  Author(s): Dru Staltman, John Comes
--**
--**  Summary  : Generic AI Platoon Build Conditions
--**             Build conditions always return true or false
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local GetEconomyTrend = moho.aibrain_methods.GetEconomyTrend
local GetEconomyStoredRatio = moho.aibrain_methods.GetEconomyStoredRatio
local GetEconomyIncome = moho.aibrain_methods.GetEconomyIncome
local GetEconomyRequested = moho.aibrain_methods.GetEconomyRequested
local GetEconomyStored = moho.aibrain_methods.GetEconomyStored
local ParagonCat = categories.STRUCTURE * categories.EXPERIMENTAL * categories.ECONOMIC * categories.ENERGYPRODUCTION * categories.MASSPRODUCTION

---GreaterThanEconStorageRatio = BuildCondition
---@param aiBrain AIBrain
---@param mStorageRatio number
---@param eStorageRatio number
---@return boolean
function GreaterThanEconStorageRatio(aiBrain, mStorageRatio, eStorageRatio)
    if GetEconomyStoredRatio(aiBrain, 'MASS') >= mStorageRatio and GetEconomyStoredRatio(aiBrain, 'ENERGY') >= eStorageRatio then
        return true
    end
    return false
end

---GreaterThanEconStorageMax = BuildCondition
---@param aiBrain AIBrain
---@param mStorage number
---@param eStorage number
---@return boolean
function GreaterThanEconStorageMax(aiBrain, mStorage, eStorage)
    local massMaxStored
    local energyMaxStored
    local massStorageRatio = GetEconomyStoredRatio(aiBrain, 'MASS')
    local energyStorageRatio = GetEconomyStoredRatio(aiBrain, 'ENERGY')

    if massStorageRatio ~= 0 then
        massMaxStored = GetEconomyStored('MASS') / massStorageRatio
    else
        massMaxStored = GetEconomyStored('MASS')
    end
    if energyStorageRatio ~= 0 then
        energyMaxStored = GetEconomyStored('ENERGY') / energyStorageRatio
    else
        energyMaxStored = GetEconomyStored('ENERGY')
    end

    if (massMaxStored >= mStorage and energyMaxStored >= eStorage) then
        return true
    end
    return false
end

---GreaterThanEconStorageCurrent = BuildCondition
---@param aiBrain AIBrain
---@param mStorage number
---@param eStorage number
---@return boolean
function GreaterThanEconStorageCurrent(aiBrain, mStorage, eStorage)
    if GetEconomyStored(aiBrain, 'MASS') >= mStorage and GetEconomyStored(aiBrain, 'ENERGY') >= eStorage then
        return true
    end
    return false
end

--- Returns true if energy in storage of <aiBrain> is greater than <eStorage>
---@param aiBrain AIBrain
---@param eStorage number
---@return boolean
function GreaterThanEnergyStorageCurrent(aiBrain, eStorage)
    if GetEconomyStored(aiBrain, 'ENERGY') > eStorage then
        return true
    end
    return false
end

--- Returns true if mass in storage of <aiBrain> is greater than <mStorage>
---@param aiBrain AIBrain
---@param mStorage number
---@return boolean
function GreaterThanMassStorageCurrent(aiBrain, mStorage)
    if GetEconomyStored(aiBrain, 'MASS') > mStorage then
        return true
    end
    return false
end

---LessThanEconTrend = BuildCondition
---@param aiBrain AIBrain
---@param mTrend number
---@param eTrend number
---@return boolean
function LessThanEconTrend(aiBrain, mTrend, eTrend)
    if GetEconomyTrend(aiBrain, 'MASS') < mTrend and GetEconomyTrend(aiBrain, 'ENERGY') < eTrend then
        return true
    end
    return false
end

---LessThanEconStorageRatio = BuildCondition
---@param aiBrain AIBrain
---@param mStorageRatio number
---@param eStorageRatio number
---@return boolean
function LessThanEconStorageRatio(aiBrain, mStorageRatio, eStorageRatio)
    if GetEconomyStoredRatio(aiBrain, 'MASS') < mStorageRatio and GetEconomyStoredRatio(aiBrain, 'ENERGY') < eStorageRatio then
        return true
    end
    return false
end

---LessEconStorageMax = BuildCondition
---@param aiBrain AIBrain
---@param mStorage number
---@param eStorage number
---@return boolean
function LessEconStorageMax(aiBrain, mStorage, eStorage)
    local massMaxStored
    local energyMaxStored
    local massStorageRatio = GetEconomyStoredRatio(aiBrain, 'MASS')
    local energyStorageRatio = GetEconomyStoredRatio(aiBrain, 'ENERGY')

    if massStorageRatio ~= 0 then
        massMaxStored = GetEconomyStored('MASS') / massStorageRatio
    else
        massMaxStored = GetEconomyStored('MASS')
    end
    if energyStorageRatio ~= 0 then
        energyMaxStored = GetEconomyStored('ENERGY') / energyStorageRatio
    else
        energyMaxStored = GetEconomyStored('ENERGY')
    end

    if (massMaxStored < mStorage and energyMaxStored < eStorage) then
        return true
    end
    return false
end

---LessEconStorageCurrent = BuildCondition
---@param aiBrain AIBrain
---@param mStorage number
---@param eStorage number
---@return boolean
function LessEconStorageCurrent(aiBrain, mStorage, eStorage)
    if GetEconomyStored(aiBrain, 'MASS') < mStorage and GetEconomyStored(aiBrain, 'ENERGY') < eStorage then
        return true
    end
    return false
end

--- Returns true if energy in storage of <aiBrain> is less than <eStorage>
---@param aiBrain AIBrain
---@param eStorage number
---@return boolean
function LessThanEnergyStorageCurrent(aiBrain, eStorage)
    if GetEconomyStored(aiBrain, 'ENERGY') < eStorage then
        return true
    end
    return false
end

--- Returns true if mass in storage of <aiBrain> is less than <mStorage>
---@param aiBrain AIBrain
---@param mStorage number
---@return boolean
function LessThanMassStorageCurrent(aiBrain, mStorage)
    if GetEconomyStored(aiBrain, 'MASS') < mStorage then
        return true
    end
    return false
end

---GreaterThanEconTrend = BuildCondition
---@param aiBrain AIBrain
---@param MassTrend number
---@param EnergyTrend number
---@return boolean
function GreaterThanEconTrend(aiBrain, MassTrend, EnergyTrend)
    if GetEconomyTrend(aiBrain, 'MASS') >= MassTrend and GetEconomyTrend(aiBrain, 'ENERGY') >= EnergyTrend then
        return true
    end
    return false
end

---LessThanEnergyTrendOverTime = BuildCondition
---@param aiBrain AIBrain
---@param EnergyTrend number
---@return boolean
function LessThanEnergyTrendOverTime(aiBrain, EnergyTrend)
    if aiBrain.EconomyOverTimeCurrent.EnergyTrendOverTime < EnergyTrend then
        return true
    end
    return false
end

---GreaterThanEconIncome = BuildCondition
---@param aiBrain AIBrain
---@param MassIncome number
---@param EnergyIncome number
---@return boolean
function GreaterThanEconIncome(aiBrain, MassIncome, EnergyIncome)
    if HaveGreaterThanUnitsWithCategory(aiBrain, 0, ParagonCat) then
        --LOG('*AI DEBUG: Found Paragon')
        return true
    end
    if (GetEconomyIncome(aiBrain,'MASS') >= MassIncome and GetEconomyIncome(aiBrain,'ENERGY') >= EnergyIncome) then
        return true
    end
    return false
end

---LessThanEconIncome = BuildCondition
---@param aiBrain AIBrain
---@param MassIncome number
---@param EnergyIncome number
---@return boolean
function LessThanEconIncome(aiBrain, MassIncome, EnergyIncome)
    if HaveGreaterThanUnitsWithCategory(aiBrain, 0, ParagonCat) then
        --LOG('*AI DEBUG: Found Paragon')
        return false
    end
    if (GetEconomyIncome(aiBrain,'MASS') < MassIncome and GetEconomyIncome(aiBrain,'ENERGY') < EnergyIncome) then
        return true
    end
    return false
end

---GreaterThanEconIncomeOverTime = BuildCondition
---@param aiBrain AIBrain
---@param MassIncome number
---@param EnergyIncome number
---@return boolean
function GreaterThanEconIncomeOverTime(aiBrain, MassIncome, EnergyIncome)
    if HaveGreaterThanUnitsWithCategory(aiBrain, 0, ParagonCat) then
        --LOG('*AI DEBUG: Found Paragon')
        return true
    end
    if aiBrain.EconomyOverTimeCurrent.MassIncome >= MassIncome and aiBrain.EconomyOverTimeCurrent.EnergyIncome >= EnergyIncome then
        return true
    end
    return false
end

---LessThanEconEfficiency = BuildCondition
---@param aiBrain AIBrain
---@param MassEfficiency number
---@param EnergyEfficiency number
---@return boolean
function GreaterThanEconEfficiency(aiBrain, MassEfficiency, EnergyEfficiency)
    if HaveGreaterThanUnitsWithCategory(aiBrain, 0, ParagonCat) then
        --LOG('*AI DEBUG: Found Paragon')
        return true
    end
    local EnergyEfficiencyCurrent = math.min(GetEconomyIncome(aiBrain,'ENERGY') / GetEconomyRequested(aiBrain,'ENERGY'), 2)
    local MassEfficiencyCurrent = math.min(GetEconomyIncome(aiBrain,'MASS') / GetEconomyRequested(aiBrain,'MASS'), 2)
    if (MassEfficiencyCurrent >= MassEfficiency and EnergyEfficiencyCurrent >= EnergyEfficiency) then
        return true
    end
    return false
end

---comment
---@param aiBrain AIBrain
---@param MassEfficiency number
---@param EnergyEfficiency number
---@return boolean
function LessThanEconEfficiency(aiBrain, MassEfficiency, EnergyEfficiency)
    if HaveGreaterThanUnitsWithCategory(aiBrain, 0, ParagonCat) then
        --LOG('*AI DEBUG: Found Paragon')
        return false
    end
    local EnergyEfficiencyCurrent = math.min(GetEconomyIncome(aiBrain,'ENERGY') / GetEconomyRequested(aiBrain,'ENERGY'), 2)
    local MassEfficiencyCurrent = math.min(GetEconomyIncome(aiBrain,'MASS') / GetEconomyRequested(aiBrain,'MASS'), 2)
    if (MassEfficiencyCurrent <= MassEfficiency and EnergyEfficiencyCurrent <= EnergyEfficiency) then
        return true
    end
    return false
end

---LessThanEconEfficiencyOverTime = BuildCondition
---@param aiBrain AIBrain
---@param MassEfficiency number
---@param EnergyEfficiency number
---@return boolean
function GreaterThanEconEfficiencyOverTime(aiBrain, MassEfficiency, EnergyEfficiency)
    if HaveGreaterThanUnitsWithCategory(aiBrain, 0, ParagonCat) then
        --LOG('*AI DEBUG: Found Paragon')
        return true
    end
    if (aiBrain.EconomyOverTimeCurrent.MassEfficiencyOverTime >= MassEfficiency and 
    aiBrain.EconomyOverTimeCurrent.EnergyEfficiencyOverTime >= EnergyEfficiency) then
        return true
    end
    return false
end

---comment
---@param aiBrain AIBrain
---@param MassEfficiency number
---@param EnergyEfficiency number
---@return boolean
function LessThanEconEfficiencyOverTime(aiBrain, MassEfficiency, EnergyEfficiency)
    if HaveGreaterThanUnitsWithCategory(aiBrain, 0, ParagonCat) then
        --LOG('*AI DEBUG: Found Paragon')
        return false
    end
    if (aiBrain.EconomyOverTimeCurrent.MassEfficiencyOverTime <= MassEfficiency and 
    aiBrain.EconomyOverTimeCurrent.EnergyEfficiencyOverTime <= EnergyEfficiency) then
        return true
    end
    return false
end

---GreaterThanEconEfficiencyCombined = BuildCondition
---@param aiBrain AIBrain
---@param MassEfficiency number
---@param EnergyEfficiency number
---@return boolean
function GreaterThanEconEfficiencyCombined(aiBrain, MassEfficiency, EnergyEfficiency)
    if (aiBrain.EconomyOverTimeCurrent.MassEfficiencyOverTime >= MassEfficiency and aiBrain.EconomyOverTimeCurrent.EnergyEfficiencyOverTime >= EnergyEfficiency) then
        local EnergyEfficiencyOverTime = math.min(GetEconomyIncome(aiBrain,'ENERGY') / GetEconomyRequested(aiBrain,'ENERGY'), 2)
        local MassEfficiencyOverTime = math.min(GetEconomyIncome(aiBrain,'MASS') / GetEconomyRequested(aiBrain,'MASS'), 2)
        if (MassEfficiencyOverTime >= MassEfficiency and EnergyEfficiencyOverTime >= EnergyEfficiency) then
            return true
        end
    end
    return false
end

---comment
---@param aiBrain AIBrain
---@param ratio number
---@param compareType string
---@param unitCategory EntityCategory
---@return boolean
function MassIncomeToUnitRatio(aiBrain, ratio, compareType, unitCategory)

    local testCat = unitCategory
    if type(testCat) == 'string' then
        testCat = ParseEntityCategory(testCat)
    end
    local unitCount = aiBrain:GetCurrentUnits(testCat)

    -- Find units of this type being built or about to be built
    unitCount = unitCount + aiBrain:GetEngineerManagerUnitsBeingBuilt(testCat)

    local checkRatio = (aiBrain.EconomyOverTimeCurrent.MassIncome * 10) / unitCount

    return CompareBody(checkRatio, ratio, compareType)
end

---comment
---@param aiBrain AIBrain
---@param t1Drain number
---@param t2Drain number
---@param t3Drain number
---@return boolean
function GreaterThanMassIncomeToFactory(aiBrain, t1Drain, t2Drain, t3Drain)

    -- T1 Test
    local testCat = categories.TECH1 * categories.FACTORY
    local unitCount = aiBrain:GetCurrentUnits(testCat)
    -- Find units of this type being built or about to be built
    unitCount = unitCount + aiBrain:GetEngineerManagerUnitsBeingBuilt(testCat)

    local massTotal = unitCount * t1Drain

    -- T2 Test
    testCat = categories.TECH2 * categories.FACTORY
    unitCount = aiBrain:GetCurrentUnits(testCat)

    massTotal = massTotal + (unitCount * t2Drain)

    -- T3 Test
    testCat = categories.TECH3 * categories.FACTORY
    unitCount = aiBrain:GetCurrentUnits(testCat)

    massTotal = massTotal + (unitCount * t3Drain)

    if not CompareBody((aiBrain.EconomyOverTimeCurrent.MassIncome * 10), massTotal, '>') then
        return false
    end

    return true
end

---comment
---@param aiBrain AIBrain
---@param locationType string
---@return boolean
function MassToFactoryRatioBaseCheck(aiBrain, locationType)
    local factoryManager = aiBrain.BuilderManagers[locationType].FactoryManager
    if not factoryManager then
        WARN('*AI WARNING: FactoryCapCheck - Invalid location - ' .. locationType)
        return false
    end

    local t1 = aiBrain.BuilderManagers[locationType].BaseSettings.MassToFactoryValues.T1Value or 8
    local t2 = aiBrain.BuilderManagers[locationType].BaseSettings.MassToFactoryValues.T2Value or 20
    local t3 = aiBrain.BuilderManagers[locationType].BaseSettings.MassToFactoryValues.T3Value or 30

    return GreaterThanMassIncomeToFactory(aiBrain, t1, t2, t3)
end

---comment
---@param numOne number
---@param numTwo number
---@param compareType string
---@return boolean
function CompareBody(numOne, numTwo, compareType)
    if compareType == '>' then
        if numOne > numTwo then
            return true
        end
    elseif compareType == '<' then
        if numOne < numTwo then
            return true
        end
    elseif compareType == '>=' then
        if numOne >= numTwo then
            return true
        end
    elseif compareType == '<=' then
        if numOne <= numTwo then
            return true
        end
    else
        error('*AI ERROR: Invalid compare type: ' .. compareType)
        return false
    end
    return false
end

---comment
---@param aiBrain AIBrain
---@param numReq number
---@param category EntityCategory
---@param idleReq boolean
---@return boolean
function HaveGreaterThanUnitsWithCategory(aiBrain, numReq, category, idleReq)
    local numUnits
    local total = 0
    if type(category) == 'string' then
        category = ParseEntityCategory(category)
    end
    if not idleReq then
        numUnits = aiBrain:GetListOfUnits(category, false)
    else
        numUnits = aiBrain:GetListOfUnits(category, true)
    end
    for k,v in numUnits do
        if v:GetFractionComplete() == 1 then
            total = total + 1
            if total > numReq then
                return true
            end
        end
    end
    if total > numReq then
        return true
    end
    return false
end

--- Moved Imports that are unsed for modding support
local AIUtils = import('/lua/ai/aiutilities.lua')
local ScenarioFramework = import('/lua/scenarioframework.lua')
local ScenarioUtils = import('/lua/sim/scenarioutilities.lua')
local BuildingTemplates = import('/lua/buildingtemplates.lua')
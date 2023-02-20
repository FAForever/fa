-- File     :  /lua/AI/aibuildunits.lua
-- Author(s): John Comes
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--------------------------------------------------------------------

local AIUtils = import("/lua/ai/aiutilities.lua")
local aiEconomy

---@param aiBrain AIBrain
function AISetEconomyNumbers(aiBrain)
    --LOG('*AI DEBUG: SETTING ECONOMY NUMBERS FROM AIBRAIN ', repr(aiBrain))
    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    aiEconomy = econ
end

---@param aiBrain AIBrain
---@param unitBP UnitBlueprint
function AIModEconomyNumbers(aiBrain, unitBP)
    --LOG('*AI DEBUG: MODDING ECON NUMBERS, BRAIN = ', repr(aiBrain), ' UNITBP = ', repr(unitBP))
    --LOG('*AI DEBUG: MODDING ECON NUMBERS, ENERGYTREND BEFORE = ', repr(aiEconomy.EnergyTrend))
    --LOG('*AI DEBUG: MODDING ECON NUMBERS, ENERGY USE OF UNIT = ', repr(aiBrain:GetUnitBlueprint(unitBP).Economy.ActiveConsumptionPerSecondEnergy * 0.1))
    aiEconomy.MassTrend = aiEconomy.MassTrend - (aiBrain:GetUnitBlueprint(unitBP).Economy.ActiveConsumptionPerSecondMass or 0) * 0.1
    aiEconomy.MassIncome = aiEconomy.MassIncome - (aiBrain:GetUnitBlueprint(unitBP).Economy.ActiveConsumptionPerSecondMass or 0) * 0.1
    aiEconomy.EnergyTrend = aiEconomy.EnergyTrend - (aiBrain:GetUnitBlueprint(unitBP).Economy.ActiveConsumptionPerSecondEnergy or 0) * 0.1
    aiEconomy.EnergyIncome = aiEconomy.EnergyIncome - (aiBrain:GetUnitBlueprint(unitBP).Economy.ActiveConsumptionPerSecondEnergy or 0) * 0.1
    --LOG('*AI DEBUG: MODDING ECON NUMBERS, ENERGYTREND AFTER = ', repr(aiEconomy.EnergyTrend * 0.1))
end

---@param aiBrain AIBrain
---@param unitPlan any
---@param aIPlatoonTemplates any
function AIExecutePlanUnitList(aiBrain, unitPlan, aIPlatoonTemplates)
    for k, v in unitPlan do
        --Convert the name of the platoonTemplate to the actual platoon template
        local pltnTemplate = AIGetPlatoonTemplate(aiBrain, aIPlatoonTemplates, v.PlatoonTemplate)
        local spec = {}
        for ks, vs in v do
            spec[ks] = vs
        end
        spec.PlatoonTemplate = pltnTemplate
        aiBrain:PBMAddPlatoon(spec)
        v.Inserted = true
    end
end

---@param aiBrain AIBrain
---@param templateTable any
---@param name string
---@return boolean
function AIGetPlatoonTemplate(aiBrain, templateTable, name)
    for k, v in templateTable do
        if v[1] == name then
            return v
        end
    end
    error('AI BUILD UNITS ERROR: No Platoon template found named- ' .. name, 2)
    return false
end

---@param bp Blueprint
---@return number
function UnitBuildCheck( bp )
    local lowest = 4
    for k,v in bp.Categories do
        if ( v == 'BUILTBYTIER1FACTORY' or v == 'TRANSPORTBUILTBYTIER1FACTORY' ) then
            return 1
        elseif ( v == 'BUILTBYTIER2FACTORY' or v == 'TRANSPORTBUILTBYTIER2FACTORY' )and lowest > 2 then
            lowest = 2
        elseif ( v == 'BUILTBYTIER3FACTORY' or v == 'TRANSPORTBUILTBYTIER3FACTORY' )and lowest > 3 then
            lowest = 3
        end
    end
    return lowest
end

---@param aiBrain AIBrain
---@param unitPlan any
function AIExecutePlanUnitListTwo(aiBrain, unitPlan)
    for k, v in unitPlan do
        --Convert the name of the platoonTemplate to the actual platoon template
        --local pltnTemplate = AIGetPlatoonTemplate(aiBrain, aIPlatoonTemplates, v.PlatoonTemplate)
        local pltnTemplate = v.PlatoonTemplate
        local spec = {}
        for ks, vs in v do
            spec[ks] = vs
        end
        spec.PlatoonTemplate = pltnTemplate
        aiBrain:PBMAddPlatoon(spec)
        v.Inserted = true
    end
end

--- used for backwards compatibility
local Utils = import("/lua/utilities.lua")
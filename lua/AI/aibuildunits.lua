#****************************************************************************
#**
#**  File     :  /lua/AI/aibuildunits.lua
#**  Author(s): John Comes
#**
#**  Summary  :
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local ipairs = ipairs
local error = error
local aibrain_methodsGetUnitBlueprint = moho.aibrain_methods.GetUnitBlueprint
local next = next

local BaseTemplates = import('/lua/basetemplates.lua').BaseTemplates
local BuildingTemplates = import('/lua/BuildingTemplates.lua').BuildingTemplates
local Utils = import('/lua/utilities.lua')
local AIUtils = import('/lua/ai/aiutilities.lua')
local StructureUpgradeTemplates = import('/lua/upgradeTemplates.lua').StructureUpgradeTemplates
local UnitUpgradeTemplates = import('/lua/upgradeTemplates.lua').UnitUpgradeTemplates
local aiEconomy

function AISetEconomyNumbers(aiBrain)
    #LOG('*AI DEBUG: SETTING ECONOMY NUMBERS FROM AIBRAIN ', repr(aiBrain))
    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    aiEconomy = econ
end

function AIModEconomyNumbers(aiBrain, unitBP)
    #LOG('*AI DEBUG: MODDING ECON NUMBERS, BRAIN = ', repr(aiBrain), ' UNITBP = ', repr(unitBP))
    #LOG('*AI DEBUG: MODDING ECON NUMBERS, ENERGYTREND BEFORE = ', repr(aiEconomy.EnergyTrend))
    #LOG('*AI DEBUG: MODDING ECON NUMBERS, ENERGY USE OF UNIT = ', repr(aiBrain:GetUnitBlueprint(unitBP).Economy.ActiveConsumptionPerSecondEnergy * 0.1))
    aiEconomy.MassTrend = aiEconomy.MassTrend - (aibrain_methodsGetUnitBlueprint(aiBrain, unitBP).Economy.ActiveConsumptionPerSecondMass or 0) * 0.1
    aiEconomy.MassIncome = aiEconomy.MassIncome - (aibrain_methodsGetUnitBlueprint(aiBrain, unitBP).Economy.ActiveConsumptionPerSecondMass or 0) * 0.1
    aiEconomy.EnergyTrend = aiEconomy.EnergyTrend - (aibrain_methodsGetUnitBlueprint(aiBrain, unitBP).Economy.ActiveConsumptionPerSecondEnergy or 0) * 0.1
    aiEconomy.EnergyIncome = aiEconomy.EnergyIncome - (aibrain_methodsGetUnitBlueprint(aiBrain, unitBP).Economy.ActiveConsumptionPerSecondEnergy or 0) * 0.1
    #LOG('*AI DEBUG: MODDING ECON NUMBERS, ENERGYTREND AFTER = ', repr(aiEconomy.EnergyTrend * 0.1))
end


function AIExecutePlanUnitList(aiBrain, unitPlan, aIPlatoonTemplates)
    for k, v in unitPlan do
        #Convert the name of the platoonTemplate to the actual platoon template
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

function AIGetPlatoonTemplate(aiBrain, templateTable, name)
    for k, v in templateTable do
        if v[1] == name then
            return v
        end
    end
    error('AI BUILD UNITS ERROR: No Platoon template found named- ' .. name, 2)
    return false
end

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

function AIExecutePlanUnitListTwo(aiBrain, unitPlan)
    for k, v in unitPlan do
        #Convert the name of the platoonTemplate to the actual platoon template
        #local pltnTemplate = AIGetPlatoonTemplate(aiBrain, aIPlatoonTemplates, v.PlatoonTemplate)
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


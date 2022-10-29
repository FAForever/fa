--****************************************************************************
--**
--**  File     :  /lua/editor/OtherArmyUnitCountBuildConditions.lua
--**  Author(s): Dru Staltman
--**
--**  Summary  : Generic AI Platoon Build Conditions
--**             Build conditions always return true or false
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

---comment
---@param aiBrain AIBrain
---@param targetBrains string[]
---@param numReq number
---@param category EntityCategory
---@param compareType '>='|"<="|'=='|'>'|'<'|
---@return boolean
function BrainsCompareNumCategory(aiBrain, targetBrains, numReq, category, compareType)
    local num = 0

    local targetBrainSet = {}
    for _, brain in targetBrains do
        if brain == 'HumanPlayers' then
            local tblArmy = ListArmies()
            for _, strArmy in pairs(tblArmy) do
                if ScenarioInfo.ArmySetup[strArmy].Human then
                    targetBrainSet[ScenarioInfo.ArmySetup[strArmy].ArmyName] = true
                end
            end
        else
            targetBrainSet[brain] = true
        end
    end

    for brain, _ in targetBrainSet do
        for _, testBrain in ArmyBrains do
            if testBrain.Name == brain then
                num = num + testBrain:GetCurrentUnits(category)
            end
        end
    end

    if not compareType or compareType == '>=' then
        return num >= numReq
    elseif compareType == '==' then
        return num == numReq
    elseif compareType == '<=' then
        return num <= numReq
    elseif compareType == '>' then
        return num > numReq
    elseif compareType == '<' then
        return num < numReq
    else
        return false
    end
end

---@param aiBrain AIBrain
---@param targetBrain string[]
---@param numReq integer
---@param category EntityCategory
---@return boolean
function BrainGreaterThanNumCategory(aiBrain, targetBrain, numReq, category)
    return BrainsCompareNumCategory(aiBrain, targetBrain, numReq, category, ">")
end

---@param aiBrain AIBrain
---@param targetBrain string[]
---@param numReq integer
---@param category EntityCategory
---@return boolean
function BrainLessThanNumCategory(aiBrain, targetBrain, numReq, category)
    return BrainsCompareNumCategory(aiBrain, targetBrain, numReq, category, "<")
end

---@param aiBrain AIBrain
---@param targetBrain string[]
---@param numReq integer
---@param category EntityCategory
---@return boolean
function BrainGreaterThanOrEqualNumCategory(aiBrain, targetBrain, numReq, category)
    return BrainsCompareNumCategory(aiBrain, targetBrain, numReq, category, ">=")
end

---@param aiBrain AIBrain
---@param targetBrain string[]
---@param numReq integer
---@param category EntityCategory
---@return boolean
function BrainLessThanOrEqualNumCategory(aiBrain, targetBrain, numReq, category)
    return BrainsCompareNumCategory(aiBrain, targetBrain, numReq, category, "<=")
end

---@param aiBrain AIBrain
---@param numReq integer
---@param categories EntityCategory
---@param compareType string
---@return boolean
function FocusBrainBeingBuiltOrActiveCategoryCompare(aiBrain, numReq, categories, compareType)
    local num = 0
    local tblArmy = ListArmies()
    for iArmy, strArmy in pairs(tblArmy) do
        if ScenarioInfo.ArmySetup[strArmy].Human then
            local testBrain = GetArmyBrain(strArmy)
            for k, v in categories do
                num = num + testBrain:GetBlueprintStat('Units_BeingBuilt', v)
                num = num + testBrain:GetBlueprintStat('Units_Active', v)
            end
        end
    end
    if not compareType or compareType == '>=' then
        return num >= numReq
    elseif compareType == '==' then
        return num == numReq
    elseif compareType == '<=' then
        return num <= numReq
    elseif compareType == '>' then
        return num > numReq
    elseif compareType == '<' then
        return num < numReq
    else
        return false
    end
end

-- Moved unsed Imports to bottom for mod compatibilty
local AIUtils = import('/lua/ai/aiutilities.lua')
local ScenarioFramework = import('/lua/scenarioframework.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')

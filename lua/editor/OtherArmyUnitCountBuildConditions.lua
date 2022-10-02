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

---@param aiBrain AIBrain
---@param targetBrain string
---@param numReq integer
---@param category EntityCategory
---@return boolean
function BrainGreaterThanNumCategory( aiBrain, targetBrain, numReq, category )
    local testBrain = ArmyBrains[1]
    for k,v in ArmyBrains do
        if v.Name == targetBrain then
            testBrain = v
            break
        end
    end
    local numUnits = testBrain:GetCurrentUnits(category)
    if numUnits > numReq then
        return true
    else
        return false
    end
end

---@param aiBrain AIBrain
---@param targetBrain string
---@param numReq integer
---@param category EntityCategory
---@return boolean
function BrainLessThanNumCategory( aiBrain, targetBrain, numReq, category )
    local testBrain = ArmyBrains[1]
    for k,v in ArmyBrains do
        if v.Name == targetBrain then
            testBrain = v
            break
        end
    end
    local numUnits = testBrain:GetCurrentUnits(category)
    if numUnits < numReq then
        return true
    else
        return false
    end
end

---@param aiBrain AIBrain
---@param targetBrain string
---@param numReq integer
---@param category EntityCategory
---@return boolean
function BrainGreaterThanOrEqualNumCategory( aiBrain, targetBrain, numReq, category )
    local testBrain = ArmyBrains[1]
    for k,v in ArmyBrains do
        if v.Name == targetBrain then
            testBrain = v
            break
        end
    end
    local numUnits = testBrain:GetCurrentUnits(category)
    if numUnits >= numReq then
        return true
    else
        return false
    end
end

---@param aiBrain AIBrain
---@param targetBrain string
---@param numReq integer
---@param category EntityCategory
---@return boolean
function BrainLessThanOrEqualNumCategory( aiBrain, targetBrain, numReq, category )
    local testBrain = ArmyBrains[1]
    for k,v in ArmyBrains do
        if v.Name == targetBrain then
            testBrain = v
            break
        end
    end
    local numUnits = testBrain:GetCurrentUnits(category)
    if numUnits <= numReq then
        return true
    else
        return false
    end
end

---@param aiBrain AIBrain
---@param numReq integer
---@param categories EntityCategory
---@param compareType string
---@return boolean
function FocusBrainBeingBuiltOrActiveCategoryCompare( aiBrain, numReq, categories, compareType )
    local testBrain = ArmyBrains[GetFocusArmy()]
    local num = 0
    for k,v in categories do
        num = num + testBrain:GetBlueprintStat('Units_BeingBuilt', v)
        num = num + testBrain:GetBlueprintStat('Units_Active', v)
    end

    if not compareType or compareType == '>=' then
        if num >= numReq then
            return true
        end
    elseif compareType == '==' then
        if num == numReq then
            return true
        end
    elseif compareType == '<=' then
        if num <= numReq then
            return true
        end
    elseif compareType == '>' then
        if num > numReq then
            return true
        end
    elseif compareType == '<' then
        if num < numReq then
            return true
        end
    end
    return false
end

-- Moved unsed Imports to bottom for mod compatibilty
local AIUtils = import('/lua/ai/aiutilities.lua')
local ScenarioFramework = import('/lua/scenarioframework.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
--****************************************************************************
--**
--**  File     :  /lua/editor/InstantBuildConditions.lua
--**  Author(s): Dru Staltman
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

---@param aiBrain AIBrain
---@return boolean
function PreBuiltBase(aiBrain)
    if aiBrain.PreBuilt then
        return true
    else
        return false
    end
end

---@param aiBrain AIBrain
---@return boolean
function NotPreBuilt(aiBrain)
    if not aiBrain.PreBuilt then
        return true
    else
        return false
    end
end

---@param aiBrain AIBrain
---@param numReq number
---@param category EntityCategory
---@param idleReq boolean
---@return boolean
function HaveEqualToUnitsWithCategory(aiBrain, numReq, category, idleReq)
    local numUnits
    if not idleReq then
        numUnits = aiBrain:GetCurrentUnits(category)
    else
        numUnits = table.getn(aiBrain:GetListOfUnits(category, true))
    end
    if numUnits == numReq then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param numReq number
---@param category EntityCategory
---@param idleReq EntityCategory
---@return boolean
function HaveGreaterThanUnitsWithCategory(aiBrain, numReq, category, idleReq)
    local numUnits
    if not idleReq then
        numUnits = aiBrain:GetCurrentUnits(category)
    else
        numUnits = table.getn(aiBrain:GetListOfUnits(category, true))
    end
    if numUnits > numReq then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param numReq number
---@param category EntityCategory
---@param idleReq EntityCategory
---@return boolean
function HaveLessThanUnitsWithCategory(aiBrain, numReq, category, idleReq)
    local numUnits
    if not idleReq then
        numUnits = aiBrain:GetCurrentUnits(category)
    else
        numUnits = table.getn(aiBrain:GetListOfUnits(category, true))
    end
    if numUnits < numReq then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@return boolean
function BrainNotLowPowerMode(aiBrain)
    if not aiBrain.LowEnergyMode then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@return boolean
function BrainNotLowMassMode(aiBrain)
    if not aiBrain.LowMassMode then
        return true
    end
    return false
end

-- Moved Unused Imports to bottom for mod support
local AIUtils = import("/lua/ai/aiutilities.lua")
local ScenarioFramework = import("/lua/scenarioframework.lua")
local ScenarioUtils = import("/lua/sim/scenarioutilities.lua")
local Utils = import("/lua/utilities.lua")
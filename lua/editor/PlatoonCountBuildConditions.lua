--------------------------------------------------------------------------------------------------
--  File     :  /lua/editor/PlatoonCountBuildConditions.lua
--  Author(s): Dru Staltman, John Comes
--  Summary  : Generic AI Platoon Build Conditions. Build conditions always return true or false
--
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--------------------------------------------------------------------------------------------------

--- NOTE: ScenarioInfo.VarTable and Scenarinfo.OSPlatoonCounter are both tables that are initialized in "lua/simInit.lua"
--- The build conditions were refactored with that in mind, so if either of those 2 are nil/invalid, then something has gone wrong during the initialization

---@param aiBrain AIBrain
---@param name string
---@param varName string
---@return boolean
function AMPlatoonsGreaterOrEqualVarTable(aiBrain, name, varName)
	local counter = aiBrain.AttackData.AMPlatoonCount[name] or 0
	local num = ScenarioInfo.VarTable[varName]
	
	if not num then
		return false
	end
	
	return counter >= num
end

---@param aiBrain AIBrain
---@param name string
---@param varName string
---@return boolean
function AMPlatoonsLessThanVarTable(aiBrain, name, varName)
	local counter = aiBrain.AttackData.AMPlatoonCount[name] or 0
	local num = ScenarioInfo.VarTable[varName]
	
	if not num then
		return false
	end
	
	return counter < num
end

---@param aiBrain AIBrain
---@param name1 string
---@param name2 string
---@return boolean
function NumBuilderPlatoonsGreaterOrEqualNumBuilderPlatoons(aiBrain, name1, name2)
	local builder1Count = aiBrain.PlatoonNameCounter[name1] or 0
    local builder2Count = aiBrain.PlatoonNameCounter[name2] or 0
	
	return builder1Count >= builder2Count
end

---@param aiBrain AIBrain
---@param name1 string
---@param name2 string
---@return boolean
function NumBuilderPlatoonsLessThanNumBuilderPlatoons(aiBrain, name1, name2)
	local builder1Count = aiBrain.PlatoonNameCounter[name1] or 0
    local builder2Count = aiBrain.PlatoonNameCounter[name2] or 0
	
	return builder1Count < builder2Count
end

---@param aiBrain AIBrain
---@param name string
---@param varName string
---@return boolean
function NumBuilderPlatoonsGreaterOrEqualVarTable(aiBrain, name, varName)
	local counter = aiBrain.PlatoonNameCounter[name] or 0
	local num = ScenarioInfo.VarTable[varName]
	
	if not num then
		return false
	end
	
	return counter >= num
end

---@param aiBrain AIBrain
---@param name string
---@param varName string
---@return boolean
function NumBuilderPlatoonsLessThanVarTable(aiBrain, name, varName)
	local counter = aiBrain.PlatoonNameCounter[name] or 0
	local num = ScenarioInfo.VarTable[varName]
	
	if not num then
		return false
	end
	
	return counter < num
end

---@param aiBrain AIBrain
---@param name string
---@param num number
---@return boolean
function NumGreaterOrEqualAMPlatoons(aiBrain, name, num)
    return (aiBrain.AttackData.AMPlatoonCount[name] or 0) >= num
end

---@param aiBrain AIBrain
---@param name string
---@param num number
---@return boolean
function NumGreaterAMPlatoons(aiBrain, name, num)
    return (aiBrain.AttackData.AMPlatoonCount[name] or 0) > num
end

---@param aiBrain AIBrain
---@param name string
---@param num number
---@return boolean
function NumLessOrEqualAMPlatoons(aiBrain, name, num)
	return (aiBrain.AttackData.AMPlatoonCount[name] or 0) <= num
end

---@param aiBrain AIBrain
---@param name string
---@param num number
---@return boolean
function NumLessAMPlatoons(aiBrain, name, num)
	return (aiBrain.AttackData.AMPlatoonCount[name] or 0) < num
end

---@param aiBrain AIBrain
---@param builderName string
---@param num number
---@return boolean
function NumBuildersLessThanOSCounter(aiBrain, builderName, num)
	local difficulty = ScenarioInfo.Options.Difficulty or 3
	
	return (aiBrain.PlatoonNameCounter[builderName] or 0) < (ScenarioInfo.OSPlatoonCounter[builderName .. '_D' .. difficulty] or num)
end

---@param aiBrain AIBrain
---@param builderName string
---@param num number
---@return boolean
function NumBuildersGreaterThanEqualOSCounter(aiBrain, builderName, num)
	local difficulty = ScenarioInfo.Options.Difficulty or 3

	return (aiBrain.PlatoonNameCounter[builderName] or 0) >= (ScenarioInfo.OSPlatoonCounter[builderName .. '_D' .. difficulty] or num)
end

-- Moved Unsused Imports to bottom for mod support
local AIUtils = import("/lua/ai/aiutilities.lua")
local ScenarioFramework = import("/lua/scenarioframework.lua")
local ScenarioUtils = import("/lua/sim/scenarioutilities.lua")
----------------------------------------------------------------------------------------------------
-- File     :  /lua/ai/OpAI/BasicLandAttack_EditorFunctions
-- Author(s): Dru Staltman
-- Summary  : Generic AI Platoon Build Conditions. Build conditions always return true or false
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
----------------------------------------------------------------------------------------------------

local AIUtils = import("/lua/ai/aiutilities.lua")
local ScenarioFramework = import("/lua/scenarioframework.lua")

--- BasicLandAttackChildCountDifficulty = BuildCondition   doc = "Please work function docs."
---@param aiBrain AIBrain default_brain
---@param master string default_master
---@return boolean
function BasicLandAttackChildCountDifficulty(aiBrain, master)
    local counter = ScenarioFramework.AMPlatoonCounter(aiBrain, master)
    local difficulty = ScenarioInfo.Options.Difficulty
    local number = ScenarioInfo.OSPlatoonCounter[master .. "_D" .. difficulty] or difficulty or 3
    return counter < number
end

--- BasicLandAttackMasterCountDifficulty = BuildCondition   doc = "Please work function docs."
---@param aiBrain AIBrain default_brain
---@param master string default_master
---@return boolean
function BasicLandAttackMasterCountDifficulty(aiBrain, master)
    local counter = ScenarioFramework.AMPlatoonCounter(aiBrain, master)
    local difficulty = ScenarioInfo.Options.Difficulty
    local number = ScenarioInfo.OSPlatoonCounter[master .. "_D" .. difficulty] or difficulty or 3
    return counter >= number
end

---@param aiBrain AIBrain
---@param masterName string
---@param locationName Vector
---@return boolean
function NeedTransports(aiBrain, masterName, locationName)
    if not ScenarioInfo.OSPlatoonCounter[masterName .. "_Transports"] then
        return false
    end
    local pos = aiBrain:PBMGetLocationCoords(locationName)
    local radius = 100000
    local units = AIUtils.GetOwnUnitsAroundPoint(aiBrain, categories.TRANSPORTATION, pos, radius)
    return table.getn(units) < 5
end
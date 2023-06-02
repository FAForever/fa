------------------------------------------------------------------------------
-- File     :  /lua/ai/OpAI/AirAttacks_EditorFunctions
-- Author(s): Dru Staltman
-- Summary  : Generic AI Platoon Build Conditions
--            Build conditions always return true or false
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------

local ScenarioFramework = import("/lua/scenarioframework.lua")

--- AirAttackChildCountDifficulty = BuildCondition   doc = "Please work function docs."
---@param aiBrain AIBrain default_brain
---@param master string default_master
---@param number number
---@return boolean
function AirAttackChildCountDifficulty(aiBrain, master, number)
    local counter = ScenarioFramework.AMPlatoonCounter(aiBrain, master)
    local number = ScenarioInfo.OSPlatoonCounter[master..'_D'..ScenarioInfo.Options.Difficulty]
    if not number then
        if ScenarioInfo.Options.Difficulty == 1 then
            number = 1
        elseif ScenarioInfo.Options.Difficulty == 2 then
            number = 2
        else
            number = 3
        end
    end
    if counter < number then
        return true
    else
        return false
    end
end

--- AirAttackMasterCountDifficulty = BuildCondition   doc = "Please work function docs."
---@param aiBrain AIBrain default_brain
---@param master string default_master
---@param number number
---@return boolean
function AirAttackMasterCountDifficulty(aiBrain, master, number)
    local counter = ScenarioFramework.AMPlatoonCounter(aiBrain, master)
    local number = ScenarioInfo.OSPlatoonCounter[master..'_D'..ScenarioInfo.Options.Difficulty]
    if not number then
        if ScenarioInfo.Options.Difficulty == 1 then
            number = 1
        elseif ScenarioInfo.Options.Difficulty == 2 then
            number = 2
        else
            number = 3
        end
    end
    if counter >= number then
        return true
    else
        return false
    end
end
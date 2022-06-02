--****************************************************************************
--**
--**  File     :  /lua/ai/OpAI/AirAttacks_EditorFunctions
--**  Author(s): Dru Staltman
--**
--**  Summary  : Generic AI Platoon Build Conditions
--**             Build conditions always return true or false
--**
--**  Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local AIUtils = import('/lua/ai/aiutilities.lua')
local ScenarioFramework = import('/lua/scenarioframework.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local ScenarioPlatoonAI = import('/lua/ScenarioPlatoonAI.lua')

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- function: AirAttackChildCountDifficulty = BuildCondition   doc = "Please work function docs."
--
-- parameter 0: string   aiBrain     = "default_brain"
-- parameter 1: string   master     = "default_master"
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- function: AirAttackMasterCountDifficulty = BuildCondition   doc = "Please work function docs."
--
-- parameter 0: string   aiBrain     = "default_brain"
-- parameter 1: string   master     = "default_master"
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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

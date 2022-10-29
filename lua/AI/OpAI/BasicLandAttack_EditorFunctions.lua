--****************************************************************************
--**
--**  File     :  /lua/ai/OpAI/BasicLandAttack_EditorFunctions
--**  Author(s): Dru Staltman
--**
--**  Summary  : Generic AI Platoon Build Conditions
--**             Build conditions always return true or false
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local AIUtils = import('/lua/ai/aiutilities.lua')
local ScenarioFramework = import('/lua/scenarioframework.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local ScenarioPlatoonAI = import('/lua/ScenarioPlatoonAI.lua')

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- function: BasicLandAttackChildCountDifficulty = BuildCondition   doc = "Please work function docs."
--
-- parameter 0: string   aiBrain     = "default_brain"
-- parameter 1: string   master     = "default_master"
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function BasicLandAttackChildCountDifficulty(aiBrain, master)
    local counter = ScenarioFramework.AMPlatoonCounter(aiBrain, master)
    local number = ScenarioInfo.OSPlatoonCounter[master .. '_D' .. ScenarioInfo.Options.Difficulty]
    number = number or ScenarioInfo.Options.Difficulty
    return counter < number
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- function: BasicLandAttackMasterCountDifficulty = BuildCondition   doc = "Please work function docs."
--
-- parameter 0: string   aiBrain     = "default_brain"
-- parameter 1: string   master     = "default_master"
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function BasicLandAttackMasterCountDifficulty(aiBrain, master)
    local counter = ScenarioFramework.AMPlatoonCounter(aiBrain, master)
    local number = ScenarioInfo.OSPlatoonCounter[master .. '_D' .. ScenarioInfo.Options.Difficulty]
    number = number or ScenarioInfo.Options.Difficulty
    return counter >= number
end



function NeedTransports(aiBrain, masterName, locationName)
    local enabled = ScenarioInfo.OSPlatoonCounter[masterName .. '_Transports']
    if not enabled then
        return false
    end

    local position, radius = aiBrain:PBMGetLocationCoords(locationName), 100000
    return (table.getn(AIUtils.GetOwnUnitsAroundPoint(aiBrain, categories.TRANSPORTATION, position, radius)) < 5)
end

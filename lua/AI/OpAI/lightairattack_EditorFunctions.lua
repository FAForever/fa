--****************************************************************************
--**
--**  File     :  /lua/ai/OpAI/lightairattack_EditorFunctions
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
-- function: LightAirChildCountDifficulty = BuildCondition   doc = "Please work function docs."
-- 
-- parameter 0: string   aiBrain     = "default_brain"     
-- parameter 1: string   master     = "default_master"
-- 
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function LightAirChildCountDifficulty(aiBrain, master)
    local counter = ScenarioFramework.AMPlatoonCounter(aiBrain, master)
    local d1Num = ScenarioInfo.OSPlatoonCounter[master..'_D1'] or 1
    local d2Num = ScenarioInfo.OSPlatoonCounter[master..'_D2'] or 2
    local d3Num = ScenarioInfo.OSPlatoonCounter[master..'_D3'] or 2
    if not ScenarioInfo.Options.Difficulty or ScenarioInfo.Options.Difficulty == 1 and counter < d1Num then
        return true
    elseif ScenarioInfo.Options.Difficulty == 2 and counter < d2Num then
        return true
    elseif ScenarioInfo.Options.Difficulty == 3 and counter < d3Num then
        return true
    else
        return false        
    end
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- function: LightAirMasterCountDifficulty = BuildCondition   doc = "Please work function docs."
-- 
-- parameter 0: string   aiBrain     = "default_brain"       
-- parameter 1: string   master     = "default_master"
-- 
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function LightAirMasterCountDifficulty(aiBrain, master)
    local counter = ScenarioFramework.AMPlatoonCounter(aiBrain, master)
    local d1Num = ScenarioInfo.OSPlatoonCounter[master..'_D1'] or 1
    local d2Num = ScenarioInfo.OSPlatoonCounter[master..'_D2'] or 2
    local d3Num = ScenarioInfo.OSPlatoonCounter[master..'_D3'] or 2
    if not ScenarioInfo.Options.Difficulty or ScenarioInfo.Options.Difficulty == 1 and counter >= d1Num then
        return true
    elseif ScenarioInfo.Options.Difficulty == 2 and counter >= d2Num then
        return true
    elseif ScenarioInfo.Options.Difficulty == 3 and counter >= d3Num then
        return true
    else
        return false        
    end
end

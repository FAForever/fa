-- --****************************************************************************
-- --**
-- --**  File     :  /lua/ai/OpAI/NavalAttacks_EditorFunctions
-- --**  Author(s): speed2
-- --**
-- --**  Summary  : Generic AI Platoon Build Conditions
-- --**             Build conditions always return true or false
-- --**
-- --****************************************************************************
local ScenarioFramework = import("/lua/scenarioframework.lua")

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- -- function: NavalAttacksChildCountDifficulty = BuildCondition   doc = "Please work function docs."
-- --
-- -- parameter 0: string   aiBrain     = "default_brain"
-- -- parameter 1: string   master     = "default_master"
-- --
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function NavalAttacksChildCountDifficulty(aiBrain, master, number)
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

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- -- function: NavalAttacksMasterCountDifficulty = BuildCondition   doc = "Please work function docs."
-- --
-- -- parameter 0: string   aiBrain     = "default_brain"
-- -- parameter 1: string   master     = "default_master"
-- --
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function NavalAttacksMasterCountDifficulty(aiBrain, master, number)
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
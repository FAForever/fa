----------------------------------------------------------------------------------------------------
-- File     :  /lua/ai/OpAI/NavalAttacks_EditorFunctions
-- Author(s): speed2
-- Summary  : Generic AI Platoon Build Conditions. Build conditions always return true or false
----------------------------------------------------------------------------------------------------
local ScenarioFramework = import("/lua/scenarioframework.lua")

--- NavalAttacksChildCountDifficulty = BuildCondition   doc = "Please work function docs."
---@param aiBrain AIBrain
---@param master string
---@param number number
---@return boolean
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

--- NavalAttacksMasterCountDifficulty = BuildCondition   doc = "Please work function docs."
---@param aiBrain AIBrain
---@param master string
---@param number number
---@return boolean
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
#****************************************************************************
#**
#**  File     :  /lua/ai/OpAI/BasicLandAttack_EditorFunctions
#**  Author(s): Dru Staltman
#**
#**  Summary  : Generic AI Platoon Build Conditions
#**             Build conditions always return true or false
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local tableGetn = table.getn

local AIUtils = import('/lua/ai/aiutilities.lua')
local ScenarioFramework = import('/lua/scenarioframework.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local ScenarioPlatoonAI = import('/lua/ScenarioPlatoonAI.lua')

##############################################################################################################
# function: BasicLandAttackChildCountDifficulty = BuildCondition   doc = "Please work function docs."
#
# parameter 0: string   aiBrain     = "default_brain"
# parameter 1: string   master     = "default_master"
#
##############################################################################################################
function BasicLandAttackChildCountDifficulty(aiBrain, master, number)
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

##############################################################################################################
# function: BasicLandAttackMasterCountDifficulty = BuildCondition   doc = "Please work function docs."
#
# parameter 0: string   aiBrain     = "default_brain"
# parameter 1: string   master     = "default_master"
#
##############################################################################################################
function BasicLandAttackMasterCountDifficulty(aiBrain, master, number)
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

function NeedTransports(aiBrain, masterName, locationName)
    local enabled = ScenarioInfo.OSPlatoonCounter[masterName..'_Transports']
    if not enabled then
        return false
    end
    
    local position, radius
    position = aiBrain:PBMGetLocationCoords(locationName)
    radius = 100000 --aiBrain:PBMGetLocationRadius(locationName)
    if tableGetn(AIUtils.GetOwnUnitsAroundPoint( aiBrain, categories.TRANSPORTATION, position, radius)) < 5 then
        return true
    end
    
    return false
end
#****************************************************************************
#**
#**  File     :  /lua/ai/OpAI/BomberEscort_EditorFunctions
#**  Author(s): Dru Staltman
#**
#**  Summary  : Generic AI Platoon Build Conditions
#**             Build conditions always return true or false
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local AIUtils = import('/lua/ai/aiutilities.lua')
local ScenarioFramework = import('/lua/scenarioframework.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local ScenarioPlatoonAI = import('/lua/ScenarioPlatoonAI.lua')

##############################################################################################################
# function: BomberEscortChildBomberCountDifficulty = BuildCondition   doc = "Please work function docs."
# 
# parameter 0: string   aiBrain     = "default_brain"     
# parameter 1: string   master     = "default_master"
# 
##############################################################################################################
function BomberEscortChildBomberCountDifficulty(aiBrain, master)
    local counter = ScenarioFramework.AMPlatoonCounter(aiBrain, master..'_BomberChildren')
    local num = ScenarioInfo.OSPlatoonCounter[master..'_BomberChildren_D'..ScenarioInfo.Options.Difficulty]
    if not num then
        if ScenarioInfo.Options.Difficulty == 1 then
            num = 1
        else
            num = 2
        end
    end
    if counter < num then
        return true
    else
        return false        
    end
end

##############################################################################################################
# function: BomberEscortChildEscortCountDifficulty = BuildCondition   doc = "Please work function docs."
# 
# parameter 0: string   aiBrain     = "default_brain"     
# parameter 1: string   master     = "default_master"
# 
##############################################################################################################
function BomberEscortChildEscortCountDifficulty(aiBrain, master)
    local counter = ScenarioFramework.AMPlatoonCounter(aiBrain, master..'_EscortChildren')
    local num = ScenarioInfo.OSPlatoonCounter[master..'_EscortChildren_D'..ScenarioInfo.Options.Difficulty]
    if not num then
        if ScenarioInfo.Options.Difficulty <= 2 then
            num = 1
        else
            num = 2
        end
    end
    if counter < num then
        return true
    else
        return false        
    end
end

##############################################################################################################
# function: BomberEscortMasterCountDifficulty = BuildCondition   doc = "Please work function docs."
# 
# parameter 0: string   aiBrain     = "default_brain"       
# parameter 1: string   master     = "default_master"
# 
##############################################################################################################
function BomberEscortMasterCountDifficulty(aiBrain, master)
    local escortCounter = ScenarioFramework.AMPlatoonCounter(aiBrain, master..'_EscortChildren')
    local escortNum = ScenarioInfo.OSPlatoonCounter[master..'_EscortChildren_D'..ScenarioInfo.Options.Difficulty]
    local bomberCounter = ScenarioFramework.AMPlatoonCounter(aiBrain, master..'_BomberChildren')
    local bomberNum = ScenarioInfo.OSPlatoonCounter[master..'_BomberChildren_D'..ScenarioInfo.Options.Difficulty]
    if not bomberNum then
        if ScenarioInfo.Options.Difficulty == 1 then
            bomberNum = 1
        else
            bomberNum = 2
        end
    end
    if not escortNum then
        if ScenarioInfo.Options.Difficulty <= 2 then
            escortNum = 1
        else
            escortNum = 2
        end
    end
    if bomberCounter >= bomberNum and escortCounter >= escortNum then
        return true
    else
        return false        
    end
end

##############################################################################################################
# function: BomberEscortAI = AddFunction   doc = "Please work function docs."
# 
# parameter 0: string   platoon     = "default_platoon"       
# 
##############################################################################################################
function BomberEscortAI(platoon)
    local aiBrain = platoon:GetBrain()
    local target = false
    #local cmd = false
    while aiBrain:PlatoonExists(platoon) do
        target = false
        if table.getn(platoon:GetSquadUnits('artillery')) > 0 then
            target = platoon:FindClosestUnit('artillery', 'Enemy', true, categories.ALLUNITS-categories.WALL)
        else
            target = platoon:FindClosestUnit('attack', 'Enemy', true, categories.ALLUNITS)
        end
        if target and not target:IsDead() then
            platoon:Stop()
            cmd = platoon:AggressiveMoveToLocation( target:GetPosition() )
        else
            platoon:AggressiveMoveToLocation( (aiBrain:GetHighestThreatPosition(2, true)) )
        end
        WaitSeconds(17)
    end
end

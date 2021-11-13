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
local platoon_methodsFindClosestUnit = moho.platoon_methods.FindClosestUnit
local aibrain_methodsPlatoonExists = moho.aibrain_methods.PlatoonExists
local tableGetn = table.getn
local platoon_methodsGetSquadUnits = moho.platoon_methods.GetSquadUnits
local platoon_methodsAggressiveMoveToLocation = moho.platoon_methods.AggressiveMoveToLocation
local aibrain_methodsGetHighestThreatPosition = moho.aibrain_methods.GetHighestThreatPosition
local platoon_methodsGetBrain = moho.platoon_methods.GetBrain

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
    local aiBrain = platoon_methodsGetBrain(platoon)
    local target = false
    #local cmd = false
    while aibrain_methodsPlatoonExists(aiBrain, platoon) do
        target = false
        if tableGetn(platoon_methodsGetSquadUnits(platoon, 'artillery')) > 0 then
            target = platoon_methodsFindClosestUnit(platoon, 'artillery', 'Enemy', true, categories.ALLUNITS-categories.WALL)
        else
            target = platoon_methodsFindClosestUnit(platoon, 'attack', 'Enemy', true, categories.ALLUNITS)
        end
        if target and not target:IsDead() then
            platoon:Stop()
            cmd = platoon_methodsAggressiveMoveToLocation(platoon,  target:GetPosition() )
        else
            platoon_methodsAggressiveMoveToLocation(platoon,  (aibrain_methodsGetHighestThreatPosition(aiBrain, 2, true)) )
        end
        WaitSeconds(17)
    end
end

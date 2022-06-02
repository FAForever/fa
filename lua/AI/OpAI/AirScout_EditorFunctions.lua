#****************************************************************************
#**
#**  File     :  /lua/ai/OpAI/AirScout_EditorFunctions
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
# function: AirScoutPatrol = AddFunction   doc = "Please work function docs."
# 
# parameter 0: string   platoon         = "default_platoon" 
# 
##############################################################################################################
function AirScoutPatrol(platoon)
    local aiBrain = platoon:GetBrain()
    local master = string.sub(platoon.PlatoonData.BuilderName, 12)
    local patrolChain = platoon.PlatoonData.PatrolChain


    if not platoon.PlatoonData.PatrolChain and Scenario.Chains[master .. '_PatrolChain'] then
        patrolChain = master .. '_PatrolChain'
    elseif Scenario.Chains[aiBrain.Name .. '_PatrolChain'] then
        patrolChain = aiBrain.Name .. '_PatrolChain'
    end

    if patrolChain then
        ScenarioFramework.PlatoonPatrolRoute(platoon, ScenarioUtils.ChainToPositions(patrolChain))
    else
        error('*AI ERROR: AirScout looking for chains --\"'..master.. '_PatrolChain\"-- or --\"'..aiBrain.Name .. '_PatrolChain\"--', 2)
    end
end

##############################################################################################################
# function: AirScoutPatrolRandom = AddFunction   doc = "Please work function docs."
# 
# parameter 0: string   platoon         = "default_platoon" 
# 
##############################################################################################################
function AirScoutPatrolRandom(platoon)
    local aiBrain = platoon:GetBrain()
    local master = string.sub(platoon.PlatoonData.BuilderName, 12)
    local patrolChain = platoon.PlatoonData.PatrolChain
    local newChain = {}

    if not platoon.PlatoonData.PatrolChain and Scenario.Chains[master .. '_PatrolChain'] then
        patrolChain = master .. '_PatrolChain'
    elseif Scenario.Chains[aiBrain.Name .. '_PatrolChain'] then
        patrolChain = aiBrain.Name .. '_PatrolChain'
    end

    if patrolChain then
        newChain = ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions(patrolChain))
        ScenarioFramework.PlatoonPatrolRoute(platoon, newChain)
    else
        error('*AI ERROR: AirScout looking for chains --\"'..master.. '_PatrolChain\"-- or --\"'..aiBrain.Name .. '_PatrolChain\"--', 2)
    end
end

##############################################################################################################
# function: AirScoutDeath = BuildCallback   doc = "Please work function docs."
# 
# 
# parameter 0: string	brain		= "default_brain"		
# parameter 1: string	platoon  	= "default_platoon"		doc = "docs for param1"
# 
##############################################################################################################
function AirScoutDeath(brain, platoon)
    local delay = 300

    #LOG('debugMatt:Scout died??????') 

    if platoon.PlatoonData.AirScoutUnlockDelay then
        delay = platoon.PlatoonData.AirScoutUnlockDelay
    end
    local platoonName = platoon.PlatoonData.PlatoonName or 'nothing'
    #LOG('debugMatt:Scout died '..platoonName) 
    ForkThread( AirScoutUnlockTimer, platoonName, delay )
end

##############################################################################################################
function AirScoutUnlockTimer(platoonName, delay)

    WaitSeconds( delay )
    #LOG('debugMatt:Scout unlocked '..platoonName..delay) 
    ScenarioInfo.AMLockTable[platoonName] = false
end
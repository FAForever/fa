-----------------------------------------------------------------------------------------------
-- File     :  /lua/ai/OpAI/AirScout_EditorFunctions
-- Author(s): Dru Staltman
-- Summary  : Generic AI Platoon Build Conditions Build conditions always return true or false
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------------------------------------
local ScenarioFramework = import("/lua/scenarioframework.lua")
local ScenarioUtils = import("/lua/sim/scenarioutilities.lua")
local ScenarioPlatoonAI = import("/lua/scenarioplatoonai.lua")

--- AirScoutPatrol = AddFunction   doc = "Please work function docs."
---@param platoon Platoon
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

--- AirScoutPatrolRandom = AddFunction   doc = "Please work function docs."
---@param platoon Platoon default_platoon
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

--- AirScoutDeath = BuildCallback   doc = "Please work function docs."
---@param brain AIBrain default_brain
---@param platoon Platoon default_platoon
function AirScoutDeath(brain, platoon)
    local delay = 300

    --LOG('debugMatt:Scout died??????') 

    if platoon.PlatoonData.AirScoutUnlockDelay then
        delay = platoon.PlatoonData.AirScoutUnlockDelay
    end
    local platoonName = platoon.PlatoonData.PlatoonName or 'nothing'
    --LOG('debugMatt:Scout died '..platoonName) 
    ForkThread( AirScoutUnlockTimer, platoonName, delay )
end

---@param platoonName string
---@param delay number
function AirScoutUnlockTimer(platoonName, delay)

    WaitSeconds( delay )
    --LOG('debugMatt:Scout unlocked '..platoonName..delay) 
    ScenarioInfo.AMLockTable[platoonName] = false
end
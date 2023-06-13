----------------------------------------------------------------------------------------------------
-- File     :  /lua/ai/OpAI/LandAssault_EditorFunctions
-- Author(s): Dru Staltman
-- Summary  : Generic AI Platoon Build Conditions. Build conditions always return true or false
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
----------------------------------------------------------------------------------------------------
local ScenarioFramework = import("/lua/scenarioframework.lua")
local ScenarioPlatoonAI = import("/lua/scenarioplatoonai.lua")

---LandAssaultChildCountDifficulty = BuildCondition   doc = "Please work function docs."
---@param aiBrain AIBrain default_brain
---@param master string default_master
---@return boolean
function LandAssaultChildCountDifficulty(aiBrain, master)
    local counter = ScenarioFramework.AMPlatoonCounter(aiBrain, master)
    local d1Num = ScenarioInfo.OSPlatoonCounter[master..'_D1'] or 3
    local d2Num = ScenarioInfo.OSPlatoonCounter[master..'_D2'] or 4
    local d3Num = ScenarioInfo.OSPlatoonCounter[master..'_D3'] or 5
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

---LandAssaultMasterCountDifficulty = BuildCondition   doc = "Please work function docs."
---@param aiBrain AIBrain
---@param master string
---@return boolean
function LandAssaultMasterCountDifficulty(aiBrain, master)
    local counter = ScenarioFramework.AMPlatoonCounter(aiBrain, master)
    local d1Num = ScenarioInfo.OSPlatoonCounter[master..'_D1'] or 3
    local d2Num = ScenarioInfo.OSPlatoonCounter[master..'_D2'] or 4
    local d3Num = ScenarioInfo.OSPlatoonCounter[master..'_D3'] or 5
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

---LandAssaultAttack = AddFunction   doc = "Please work function docs."
---@param platoon Platoon
function LandAssaultAttack(platoon)
    local aiBrain = platoon:GetBrain()
    local master = string.sub(platoon.PlatoonData.BuilderName, 12)
    local landingChain = platoon.PlatoonData.LandingChain
    local attackChain = platoon.PlatoonData.AttackChain
    local transportReturn = platoon.PlatoonData.transportReturn
    if not platoon.PlatoonData.LandingChain and Scenario.Chains[master .. '_LandingChain'] then
        landingChain = master .. '_LandingChain'
    elseif Scenario.Chains[aiBrain.Name .. '_LandingChain'] then
        landingChain = aiBrain.Name .. '_LandingChain'
    end
    if not platoon.PlatoonData.AttackChain and Scenario.Chains[master .. '_AttackChain'] then
        attackChain = master .. '_AttackChain'
    elseif Scenario.Chains[aiBrain.Name .. '_AttackChain'] then
        attackChain = aiBrain.Name .. '_AttackChain'
    end
    if not platoon.PlatoonData.TransportReturn then
        if Scenario.MasterChain._MASTERCHAIN_.Markers[master .. '_TransportReturn'] then
            platoon.PlatoonData.TransportReturn = master .. '_TransportReturn'
        elseif Scenario.MasterChain._MASTERCHAIN_.Markers[aiBrain.Name .. '_TransportReturn'] then
            platoon.PlatoonData.TransportReturn = aiBrain.Name .. '_TransportReturn'
        end
    end
    if landingChain and attackChain then
        platoon.PlatoonData.AttackChain = attackChain
        platoon.PlatoonData.LandingChain = landingChain
        ScenarioPlatoonAI.LandAssaultWithTransports(platoon)
    elseif platoon.PlatoonData.AssaultChains then
        ScenarioPlatoonAI.LandAssaultWithTransports(platoon)
    else
        error('*AI ERROR: LandAssault looking for chains --\"'..master.. '_LandingChain\"-- or --\"'..aiBrain.Name .. '_LandingChain\"-- and --\"'..master.. '_AttackChain\"-- or --\"'..aiBrain.Name .. '_AttackChain\"--', 2)
    end
end

---LandAssaultTransport = BuildCondition   doc = "Please work function docs."
---@param aiBrain AIBrain default_brain
---@param tCount number[] default_transport_count
---@return boolean
function LandAssaultTransport(aiBrain, tCount)
    local transportPool = aiBrain:GetPlatoonUniquelyNamed('TransportPool')
    
    return not( transportPool and table.getn(transportPool:GetPlatoonUnits()) > 4 ) 
end

--- LandAssaultTransportThread = AddFunction   doc = "Please work function docs."
---@param platoon Platoon default_platoon
function LandAssaultTransportThread(platoon)
    local aiBrain = platoon:GetBrain()
    local master = string.sub(platoon.PlatoonData.BuilderName, 11)
    local position = platoon.PlatoonData.TransportMoveLocation
    if not position and Scenario.MasterChain._MASTERCHAIN_.Markers[master .. '_TransportMoveLocation'] then
        position = master .. '_TransportMoveLocation'
    elseif not position and Scenario.MasterChain._MASTERCHAIN_.Markers[aiBrain.Name .. '_TransportMoveLocation'] then
        position = master .. '_TransportMoveLocation'
    end
    if position then
        platoon.PlatoonData.TransportMoveLocation = position
    end
    ScenarioPlatoonAI.TransportPool(platoon)
end
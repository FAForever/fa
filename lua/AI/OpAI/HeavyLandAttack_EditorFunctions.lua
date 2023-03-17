-----------------------------------------------------------------------------------------------------
-- File     :  /lua/ai/OpAI/HeavyLandAttack_EditorFunctions
-- Author(s): Dru Staltman
-- Summary  : Generic AI Platoon Build Conditions. Build conditions always return true or false
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------------------------------------------

local ScenarioFramework = import("/lua/scenarioframework.lua")

---HeavyLandAttackChildDirectFire = BuildCondition   doc = "Please work function docs."
---@param aiBrain AIBrain default_brain
---@param master string default_master
---@return boolean
function HeavyLandAttackChildDirectFire(aiBrain, master)
    local counter = ScenarioFramework.AMPlatoonCounter(aiBrain, master..'_DirectFireChildren')
    if not counter then
        counter = 0
    end
    local num = ScenarioInfo.OSPlatoonCounter[master..'_DirectFireChildren_D'..ScenarioInfo.Options.Difficulty]
    if not num then
        if ScenarioInfo.Options.Difficulty == 1 then
            num = 1
        elseif ScenarioInfo.Options.Difficulty == 2 then
            num = 2
        elseif ScenarioInfo.Options.Difficulty == 3 then
            num = 3
        end
    end
    if counter < num then
        return true
    else
        return false
    end
end

---HeavyLandAttackChildArtillery = BuildCondition   doc = "Please work function docs."
---@param aiBrain AIBrain default_brain
---@param master string default_master
---@return boolean
function HeavyLandAttackChildArtillery(aiBrain, master)
    local counter = ScenarioFramework.AMPlatoonCounter(aiBrain, master..'_ArtilleryChildren')
    if not counter then
        counter = 0
    end
    local num = ScenarioInfo.OSPlatoonCounter[master..'_ArtilleryChildren_D'..ScenarioInfo.Options.Difficulty]
    if not num then
        if ScenarioInfo.Options.Difficulty == 1 then
            num = 1
        elseif ScenarioInfo.Options.Difficulty == 2 then
            num = 2
        elseif ScenarioInfo.Options.Difficulty == 3 then
            num = 2
        end
    end
    if counter < num then
        return true
    else
        return false
    end
end

---HeavyLandAttackChildAntiAir = BuildCondition   doc = "Please work function docs."
---@param aiBrain AIBrain default_brain
---@param master string default_master
---@return boolean
function HeavyLandAttackChildAntiAir(aiBrain, master)
    local counter = ScenarioFramework.AMPlatoonCounter(aiBrain, master..'_AntiAirChildren')
    if not counter then
        counter = 0
    end
    local num = ScenarioInfo.OSPlatoonCounter[master..'_AntiAirChildren_D'..ScenarioInfo.Options.Difficulty]
    if not num then
        if ScenarioInfo.Options.Difficulty == 1 then
            num = 0
        elseif ScenarioInfo.Options.Difficulty >= 2 then
            num = 1
        end
    end
    if counter < num then
        return true
    else
        return false        
    end
end

---HeavyLandAttackChildDefensive = BuildCondition   doc = "Please work function docs."
---@param aiBrain AIBrain default_brain
---@param master string default_master
---@return boolean
function HeavyLandAttackChildDefensive(aiBrain, master)
    local counter = ScenarioFramework.AMPlatoonCounter(aiBrain, master..'_DefensiveChildren')
    if not counter then
        counter = 0
    end
    local num = ScenarioInfo.OSPlatoonCounter[master..'_DefensiveChildren_D'..ScenarioInfo.Options.Difficulty]
    if not num then
        if  ScenarioInfo.Options.Difficulty <= 2 then
            num = 0
        elseif ScenarioInfo.Options.Difficulty == 3 then
            num = 1
        end
    end
    if counter < num then
        return true
    else
        return false        
    end
end

---HeavyLandAttackMasterCountDifficulty = BuildCondition   doc = "Please work function docs."
---@param aiBrain AIBrain
---@param master string
---@return boolean
function HeavyLandAttackMasterCountDifficulty(aiBrain, master)
    local directFireCounter = ScenarioFramework.AMPlatoonCounter(aiBrain, master..'_DirectFireChildren')
    if not directFireCounter then
        directFireCounter = 0
        aiBrain.AttackData[master..'_DirectFireChildren'] = 0
    end
    local directFireNum = ScenarioInfo.OSPlatoonCounter[master..'_DirectFireChildren_D'..ScenarioInfo.Options.Difficulty]

    local artilleryCounter = ScenarioFramework.AMPlatoonCounter(aiBrain, master..'_ArtilleryChildren')
    if not artilleryCounter then
        artilleryCounter = 0
        aiBrain.AttackData[master..'_ArtilleryChildren'] = 0
    end
    local artilleryNum = ScenarioInfo.OSPlatoonCounter[master..'_ArtilleryChildren_D'..ScenarioInfo.Options.Difficulty]

    local antiAirCounter = ScenarioFramework.AMPlatoonCounter(aiBrain, master..'_AntiAirChildren')
    if not antiAirCounter then
        antiAirCounter = 0
        aiBrain.AttackData[master..'_AntiAirChildren'] = 0
    end
    local antiAirNum = ScenarioInfo.OSPlatoonCounter[master..'_AntiAirChildren_D'..ScenarioInfo.Options.Difficulty]

    local defensiveCounter = ScenarioFramework.AMPlatoonCounter(aiBrain, master..'_DefensiveChildren')
    if not defensiveCounter then
        defensiveCounter = 0
        aiBrain.AttackData[master..'_DefensiveChildren'] = 0
    end
    local defensiveNum = ScenarioInfo.OSPlatoonCounter[master..'_DefensiveChildren_D'..ScenarioInfo.Options.Difficulty]
    
    if not directFireNum then
        if ScenarioInfo.Options.Difficulty == 1 then
            directFireNum = 1
        elseif ScenarioInfo.Options.Difficulty == 2 then
            directFireNum = 2
        elseif ScenarioInfo.Options.Difficulty == 3 then
            directFireNum = 3
        end
    end
    if not artilleryNum then
        if ScenarioInfo.Options.Difficulty == 1 then
            artilleryNum = 1
        elseif ScenarioInfo.Options.Difficulty >= 2 then
            artilleryNum = 2
        end
    end
    if not antiAirNum then
        if ScenarioInfo.Options.Difficulty == 1 then
            antiAirNum = 0
        elseif ScenarioInfo.Options.Difficulty >= 2 then
            antiAirNum = 1
        end
    end
    if not defensiveNum then
        if ScenarioInfo.Options.Difficulty <= 2 then
            defensiveNum = 0
        elseif ScenarioInfo.Options.Difficulty == 3 then
            defensiveNum = 1
        end
    end
    if directFireCounter >= directFireNum and artilleryCounter >= artilleryNum and 
        antiAirCounter >= antiAirNum and (defensiveCounter >= defensiveNum or not CheckDefensiveBuildable(aiBrain) )then
        return true
    else
        return false        
    end
end

---@param aiBrain AIBrain
---@return boolean
function CheckDefensiveBuildable(aiBrain)
    local armyIndex = aiBrain:GetArmyIndex()
    local facIndex = aiBrain:GetFactionIndex()
    local factories = aiBrain:GetListOfUnits( categories.FACTORY * categories.LAND * (categories.TECH3 + categories.TECH2), false)
    if table.getn(factories) > 0 then
        if facIndex == 1 and factories[1]:CanBuild('uel0307') then
            return true
        elseif facIndex == 2 and factories[2]:CanBuild('ual0307') then
            return true
        elseif factories[3]:CanBuild('url0306') then
            return true
        else
            return false
        end
    else
        return false
    end
end
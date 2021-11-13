#****************************************************************************
#**
#**  File     :  /lua/ai/OpAI/HeavyLandAttack_EditorFunctions
#**  Author(s): Dru Staltman
#**
#**  Summary  : Generic AI Platoon Build Conditions
#**             Build conditions always return true or false
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local aibrain_methodsGetArmyIndex = moho.aibrain_methods.GetArmyIndex
local aibrain_methodsGetListOfUnits = moho.aibrain_methods.GetListOfUnits
local tableGetn = table.getn
local unit_methodsCanBuild = moho.unit_methods.CanBuild

local AIUtils = import('/lua/ai/aiutilities.lua')
local ScenarioFramework = import('/lua/scenarioframework.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local ScenarioPlatoonAI = import('/lua/ScenarioPlatoonAI.lua')

##############################################################################################################
# function: HeavyLandAttackChildDirectFire = BuildCondition   doc = "Please work function docs."
# 
# parameter 0: string   aiBrain     = "default_brain"     
# parameter 1: string   master     = "default_master"
# 
##############################################################################################################
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

##############################################################################################################
# function: HeavyLandAttackChildArtillery = BuildCondition   doc = "Please work function docs."
# 
# parameter 0: string   aiBrain     = "default_brain"     
# parameter 1: string   master     = "default_master"
# 
##############################################################################################################
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

##############################################################################################################
# function: HeavyLandAttackChildAntiAir = BuildCondition   doc = "Please work function docs."
# 
# parameter 0: string   aiBrain     = "default_brain"     
# parameter 1: string   master     = "default_master"
# 
##############################################################################################################
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

##############################################################################################################
# function: HeavyLandAttackChildDefensive = BuildCondition   doc = "Please work function docs."
# 
# parameter 0: string   aiBrain     = "default_brain"     
# parameter 1: string   master     = "default_master"
# 
##############################################################################################################
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

##############################################################################################################
# function: HeavyLandAttackMasterCountDifficulty = BuildCondition   doc = "Please work function docs."
# 
# parameter 0: string   aiBrain     = "default_brain"       
# parameter 1: string   master     = "default_master"
# 
##############################################################################################################
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

function CheckDefensiveBuildable(aiBrain)
    local armyIndex = aibrain_methodsGetArmyIndex(aiBrain)
    local facIndex = aiBrain:GetFactionIndex()
    local factories = aibrain_methodsGetListOfUnits(aiBrain,  categories.FACTORY * categories.LAND * (categories.TECH3 + categories.TECH2), false)
    if tableGetn(factories) > 0 then
        if facIndex == 1 and unit_methodsCanBuild(factories[1], 'uel0307') then
            return true
        elseif facIndex == 2 and unit_methodsCanBuild(factories[2], 'ual0307') then
            return true
        elseif unit_methodsCanBuild(factories[3], 'url0306') then
            return true
        else
            return false
        end
    else
        return false
    end
end

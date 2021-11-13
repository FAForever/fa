#****************************************************************************
#**
#**  File     :  /lua/editor/AMPlatoonHelperFunctions.lua
#**  Author(s): Dru Staltman
#**
#**  Summary  : Functions to help with AM Platoons
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local ForkThread = ForkThread

local AIUtils = import('/lua/ai/aiutilities.lua')
local ScenarioFramework = import('/lua/scenarioframework.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')

##############################################################################################################
# function: AMLockPlatoon = AddFunction   doc = "Please work function docs."
# 
# parameter 0: string	platoon		= "default_platoon"		
#
##############################################################################################################
function AMLockPlatoon(platoon)
    if not ScenarioInfo.AMLockTable then
        ScenarioInfo.AMLockTable = {}
    end
    ScenarioInfo.AMLockTable[platoon.PlatoonData.PlatoonName] = true
end

##############################################################################################################
# function: PBMLockAndUnlock = AddFunction   doc = "Please work function docs."
# 
# parameter 0: string	platoon		= "default_platoon"		
#
##############################################################################################################
function PBMLockAndUnlock(platoon)
    if not ScenarioInfo.AMLockTable then
        ScenarioInfo.AMLockTable = {}
    end
    ScenarioInfo.AMLockTable[platoon.PlatoonData.BuilderName] = true
    platoon:AddDestroyCallback(PlatoonDeathUnlockTimer)
end

##############################################################################################################
# function: AMUnlockPlatoon = BuildCallback   doc = "Please work function docs."
# 
# parameter 0: string	brain		= "default_brain"		
# parameter 1: string	platoon  	= "default_platoon"		doc = "docs for param1"
#
##############################################################################################################
function AMUnlockPlatoon(brain, platoon)
    if ScenarioInfo.AMLockTable and ScenarioInfo.AMLockTable[platoon.PlatoonData.PlatoonName] then
        if platoon.PlatoonData['DiffLockTimerD'..ScenarioInfo.Options.Difficulty] then
            ForkThread(UnlockTimer, platoon.PlatoonData['DiffLockTimerD'..ScenarioInfo.Options.Difficulty], platoon.PlatoonData.PlatoonName)
        elseif platoon.PlatoonData.LockTimer then
            ForkThread(UnlockTimer, platoon.PlatoonData.LockTimer, platoon.PlatoonData.PlatoonName)
        else
            ScenarioInfo.AMLockTable[platoon.PlatoonData.PlatoonName] = false
        end
    end
end

##############################################################################################################
# function: AMUnlockPlatoonTimer = BuildCallback   doc = "Please work function docs."
# 
# parameter 0: string	brain		= "default_brain"		
# parameter 1: string	platoon  	= "default_platoon"		doc = "docs for param1"
# parameter 2: int      duration        = "120"
#
##############################################################################################################
function AMUnlockPlatoonTimer(brain, platoon, duration)
    local callback = function()
                         if ScenarioInfo.AMLockTable and ScenarioInfo.AMLockTable[platoon.PlatoonData.PlatoonName] then
                             ScenarioInfo.AMLockTable[platoon.PlatoonData.PlatoonName] = false
                         end
                     end
    ScenarioFramework.CreateTimerTrigger( callback, duration )
end

##############################################################################################################
# function: AMCheckPlatoonLock = BuildCondition   doc = "Please work function docs."
# 
# parameter 0: string	brain		= "default_brain"		
# parameter 1: string	AMPlatoonName	= "default_master"		doc = "docs for param1"
#
##############################################################################################################
function AMCheckPlatoonLock(brain, AMPlatoonName)
    if ScenarioInfo.AMLockTable[AMPlatoonName] then 
        return false
    end
    return true
end

##############################################################################################################
# function: ChildCountDifficulty = BuildCondition   doc = "Please work function docs."
# 
# parameter 0: string   aiBrain     = "default_brain"     
# parameter 1: string   master     = "default_master"
# 
##############################################################################################################
function ChildCountDifficulty(aiBrain, master)
    local counter = ScenarioFramework.AMPlatoonCounter(aiBrain, master)
    local d1Num = ScenarioInfo.OSPlatoonCounter[master..'_D1'] or 1
    local d2Num = ScenarioInfo.OSPlatoonCounter[master..'_D2'] or 2
    local d3Num = ScenarioInfo.OSPlatoonCounter[master..'_D3'] or 2
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

##############################################################################################################
# function: MasterCountDifficulty = BuildCondition   doc = "Please work function docs."
# 
# parameter 0: string   aiBrain     = "default_brain"       
# parameter 1: string   master     = "default_master"
# 
##############################################################################################################
function MasterCountDifficulty(aiBrain, master)
    local counter = ScenarioFramework.AMPlatoonCounter(aiBrain, master)
    local d1Num = ScenarioInfo.OSPlatoonCounter[master..'_D1'] or 1
    local d2Num = ScenarioInfo.OSPlatoonCounter[master..'_D2'] or 2
    local d3Num = ScenarioInfo.OSPlatoonCounter[master..'_D3'] or 2
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

# === utility function === #
function UnlockTimer(time, name)
    WaitSeconds( time )
    ScenarioInfo.AMLockTable[name] = false
end

function PlatoonDeathUnlockTimer( brain, platoon )
    local time = platoon.PlatoonData['DiffLockTimerD'..ScenarioInfo.Options.Difficulty] or platoon.PlatoonData.LockTimer or 0
    ForkThread(PlatoonDeathUnlockThread, platoon.PlatoonData.BuilderName, time )
end

function PlatoonDeathUnlockThread( pName, time )
    if time > 0 then
        WaitSeconds(time)
    end
    ScenarioInfo.AMLockTable[pName] = false
end

#****************************************************************************
#**
#**  File     :  /lua/ai/OpAI/LeftoverCleanup_EditorFunctions
#**  Author(s): Dru Staltman
#**
#**  Summary  : Generic AI Platoon Build Conditions
#**             Build conditions always return true or false
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local aibrain_methodsGetPlatoonUniquelyNamed = moho.aibrain_methods.GetPlatoonUniquelyNamed
local aibrain_methodsMakePlatoon = moho.aibrain_methods.MakePlatoon
local platoon_methodsGetPlatoonUnits = moho.platoon_methods.GetPlatoonUnits
local platoon_methodsUniquelyNamePlatoon = moho.platoon_methods.UniquelyNamePlatoon
local tableGetn = table.getn

local AIUtils = import('/lua/ai/aiutilities.lua')
local ScenarioFramework = import('/lua/scenarioframework.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local ScenarioPlatoonAI = import('/lua/ScenarioPlatoonAI.lua')

##############################################################################################################
# function: LeftoverCleanupBC = BuildCondition   doc = "Please work function docs."
# 
# parameter 0: string   aiBrain     = "default_brain"     
# parameter 1: string   locationType = "default_location_type"
# 
##############################################################################################################
function LeftoverCleanupBC(aiBrain, locationType)
    local pool = aibrain_methodsGetPlatoonUniquelyNamed(aiBrain, locationType..'_LeftoverUnits')
    if not pool then
        pool = aibrain_methodsMakePlatoon(aiBrain, '', '')
        platoon_methodsUniquelyNamePlatoon(pool, locationType..'_LeftoverUnits')
        pool.PlatoonData.AMPlatoons = {locationType..'_LeftoverUnits'}
        pool:SetPartOfAttackForce()
    end
    local numUnits = tableGetn(platoon_methodsGetPlatoonUnits(pool)) 
    if numUnits > 0 then
        return true
    else
        return false
    end
end

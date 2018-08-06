#****************************************************************************
#**
#**  File     :  /lua/editor/MarkerBuildConditions.lua
#**  Author(s): John Comes, Dru Staltman
#**
#**  Summary  : Generic AI Platoon Build Conditions
#**             Build conditions always return true or false
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local AIUtils = import('/lua/ai/aiutilities.lua')
local ScenarioFramework = import('/lua/scenarioframework.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')

##############################################################################################################
# function: MarkerGreaterThanDistance = BuildCondition	doc = "Please work function docs."
# 
# parameter 0: string	aiBrain         = "default_brain"		
# parameter 1: string	markerType      = "Defensive_Point"		doc = "docs for param1"
# parameter 2: float	distance        = 1.0				doc = "docs for param1"
# parameter 3: float	threatMin       = 1.0				doc = "docs for param1"
# parameter 4: float	threatMax       = 1.0				doc = "docs for param1"
# parameter 5: int	threatRings     = 1				doc = "docs for param1"
# parameter 6: float	startX          = 1.0				doc = "docs for param1"
# parameter 7: float	startZ          = 1.0				doc = "docs for param1"
#
##############################################################################################################
function MarkerGreaterThanDistance(aiBrain, markerType, distance, threatMin, threatMax, threatRings, threatType)
    if not startX and not startZ then
         startX, startZ = aiBrain:GetArmyStartPos()
    end
    local loc
    if threatMin and threatMax and threatRings then
        loc = AIUtils.AIGetClosestThreatMarkerLoc(aiBrain, markerType, startX, startZ, threatMin, threatMax, threatRings, threatType)
    else
        loc = AIUtils.AIGetClosestMarkerLocation(aiBrain, markerType, startX, startZ)
    end
    if loc and VDist2(startX, startZ, loc[1], loc[3]) > distance then
        return true
    end
    return false
end


##############################################################################################################
# function: MarkerLessThanDistance = BuildCondition	doc = "Please work function docs."
# 
# parameter 0: string	aiBrain		= "default_brain"		
# parameter 1: string	markerType      = "Defensive_Point"		doc = "docs for param1"
# parameter 2: float	distance        = 1.0				doc = "docs for param1"
# parameter 3: float	threatMin       = 1.0				doc = "docs for param1"
# parameter 4: float	threatMax       = 1.0				doc = "docs for param1"
# parameter 5: int	threatRings     = 1				doc = "docs for param1"
# parameter 6: float	startX          = 1.0				doc = "docs for param1"
# parameter 7: float	startZ          = 1.0				doc = "docs for param1"
#
##############################################################################################################
function MarkerLessThanDistance(aiBrain, markerType, distance, threatMin, threatMax, threatRings, threatType, startX, startZ)
    if not startX and not startZ then
         startX, startZ = aiBrain:GetArmyStartPos()
    end
    local loc
    if threatMin and threatMax and threatRings then
        loc = AIUtils.AIGetClosestThreatMarkerLoc(aiBrain, markerType, startX, startZ, threatMin, threatMax, threatRings, threatType)
    else
        loc = AIUtils.AIGetClosestMarkerLocation(aiBrain, markerType, startX, startZ)
    end
    if loc and loc[1] and loc[3] then
        if VDist2(startX, startZ, loc[1], loc[3]) < distance then
            return true
        end
    end
    return false
end

function CanBuildOnMassLessThanDistance(aiBrain, locationType, distance, threatMin, threatMax, threatRings, threatType, maxNum )
    local engineerManager = aiBrain.BuilderManagers[locationType].EngineerManager
    if not engineerManager then
        WARN('*AI WARNING: Invalid location - ' .. locationType)
        return false
    end
    local position = engineerManager:GetLocationCoords()
    
    local markerTable = AIUtils.AIGetSortedMassLocations(aiBrain, maxNum, threatMin, threatMax, threatRings, threatType, position)
    if markerTable[1] and VDist3( markerTable[1], position ) < distance then
        local dist = VDist3( markerTable[1], position )
        return true
    end
    return false
end

function CanBuildFirebase( aiBrain, locationType, radius, markerType, tMin, tMax, tRings, tType, maxUnits, unitCat, markerRadius)
    local ref, refName = AIUtils.AIFindFirebaseLocation( aiBrain, locationType, radius, markerType, tMin, tMax, tRings, tType, maxUnits, unitCat, markerRadius)
    if not ref then
        return false
    end
    return true
end
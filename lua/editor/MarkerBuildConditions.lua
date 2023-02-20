-- ****************************************************************************
-- **
-- **  File     :  /lua/editor/MarkerBuildConditions.lua
-- **  Author(s): John Comes, Dru Staltman
-- **
-- **  Summary  : Generic AI Platoon Build Conditions
-- **             Build conditions always return true or false
-- **
-- **  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************

local AIUtils = import("/lua/ai/aiutilities.lua")

---@param aiBrain AIBrain
---@param markerType string
---@param distance number
---@param threatMin number
---@param threatMax number
---@param threatRings number
---@param threatType string
---@param startX number
---@param startZ number
---@return boolean
function MarkerGreaterThanDistance(aiBrain, markerType, distance, threatMin, threatMax, threatRings, threatType,startX,startZ)
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

---@param aiBrain AIBrain
---@param markerType string
---@param distance number
---@param threatMin number
---@param threatMax number
---@param threatRings number
---@param threatType string
---@param startX number
---@param startZ number
---@return boolean
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

---@param aiBrain AIBrain
---@param locationType string
---@param distance number
---@param threatMin number
---@param threatMax number
---@param threatRings number
---@param threatType string
---@param maxNum number
---@return boolean
function CanBuildOnMassLessThanDistance(aiBrain, locationType, distance, threatMin, threatMax, threatRings, threatType, maxNum )
    local engineerManager = aiBrain.BuilderManagers[locationType].EngineerManager
    if not engineerManager then
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


---@param aiBrain AIBrain
---@param locationType string
---@param radius number
---@param markerType string
---@param tMin number
---@param tMax number
---@param tRings number
---@param tType string
---@param maxUnits number
---@param unitCat any
---@param markerRadius number
---@return boolean
function CanBuildFirebase( aiBrain, locationType, radius, markerType, tMin, tMax, tRings, tType, maxUnits, unitCat, markerRadius)
    local ref, refName = AIUtils.AIFindFirebaseLocation( aiBrain, locationType, radius, markerType, tMin, tMax, tRings, tType, maxUnits, unitCat, markerRadius)
    if not ref then
        return false
    end
    return true
end

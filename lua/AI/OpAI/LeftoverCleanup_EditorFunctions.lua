--------------------------------------------------------------------------------------------------
-- File     :  /lua/ai/OpAI/LeftoverCleanup_EditorFunctions
-- Author(s): Dru Staltman
-- Summary  : Generic AI Platoon Build Conditions Build conditions always return true or false
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--------------------------------------------------------------------------------------------------

--- LeftoverCleanupBC = BuildCondition   doc = "Please work function docs."
---@param aiBrain AIBrain default_brain
---@param locationType string default_location_type
---@return boolean
function LeftoverCleanupBC(aiBrain, locationType)
    local pool = aiBrain:GetPlatoonUniquelyNamed(locationType..'_LeftoverUnits')
    if not pool then
        pool = aiBrain:MakePlatoon('', '')
        pool:UniquelyNamePlatoon(locationType..'_LeftoverUnits')
        pool.PlatoonData.AMPlatoons = {locationType..'_LeftoverUnits'}
        pool:SetPartOfAttackForce()
    end
    local numUnits = table.getn(pool:GetPlatoonUnits()) 
    if numUnits > 0 then
        return true
    else
        return false
    end
end
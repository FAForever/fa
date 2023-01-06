-- ****************************************************************************
-- **
-- **  File     :  /lua/editor/UnitCountBuildConditions.lua
-- **  Author(s): Dru Staltman, John Comes
-- **
-- **  Summary  : Generic AI Platoon Build Conditions
-- **             Build conditions always return true or false
-- **
-- **  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************

---@param aiBrain AIBrain
---@param locationType string
---@param threatValue number
---@param threatType string
---@param rings number
---@return boolean
function EnemyThreatGreaterThanValueAtBase(aiBrain, locationType, threatValue, threatType, rings)
    local testRings = rings or aiBrain.IMAPConfig.Rings + 1
    local FactoryManager = aiBrain.BuilderManagers[locationType].FactoryManager
    if not FactoryManager then
        return false
    end
    local position = FactoryManager:GetLocationCoords()
    if aiBrain:GetThreatAtPosition( position, testRings, true, threatType or 'Overall' ) > threatValue then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param locationType string
---@param threatValue number
---@param threatType string
---@param rings number
---@return boolean
function EnemyThreatLessThanValueAtBase(aiBrain, locationType, threatValue, threatType, rings)
    local testRings = rings or 10
    local FactoryManager = aiBrain.BuilderManagers[locationType].FactoryManager
    if not FactoryManager then
        return false
    end
    local position = FactoryManager:GetLocationCoords()
    if aiBrain:GetThreatAtPosition( position, testRings, true, threatType or 'Overall' ) > threatValue then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param locationType string
---@param poolType string
---@param enemyType string
---@param rings number
---@return boolean
function HaveLessThreatThanNearby( aiBrain, locationType, poolType, enemyType, rings )
    local pool = aiBrain:GetPlatoonUniquelyNamed('ArmyPool')
    local poolThreat = pool:GetPlatoonThreat( poolType, categories.ALLUNITS )
    local testRings = rings or 10
    local FactoryManager = aiBrain.BuilderManagers[locationType].FactoryManager
    if not FactoryManager then
        return false
    end
    local position = FactoryManager:GetLocationCoords()
    local enemyThreat = aiBrain:GetThreatAtPosition( position, testRings, true, enemyType )
    if poolThreat < enemyThreat then
        return true
    end
    return false
end

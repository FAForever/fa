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

local aibrain_methodsGetPlatoonUniquelyNamed = moho.aibrain_methods.GetPlatoonUniquelyNamed
local aibrain_methodsGetThreatAtPosition = moho.aibrain_methods.GetThreatAtPosition

function EnemyThreatGreaterThanValueAtBase(aiBrain, locationType, threatValue, threatType, rings)
    local testRings = rings or 10
    local FactoryManager = aiBrain.BuilderManagers[locationType].FactoryManager
    if not FactoryManager then
        return false
    end
    local position = FactoryManager:GetLocationCoords()
    if aibrain_methodsGetThreatAtPosition(aiBrain,  position, testRings, true, threatType or 'Overall' ) > threatValue then
        return true
    end
    return false
end

function EnemyThreatLessThanValueAtBase(aiBrain, locationType, threatValue, threatType, rings)
    local testRings = rings or 10
    local FactoryManager = aiBrain.BuilderManagers[locationType].FactoryManager
    if not FactoryManager then
        return false
    end
    local position = FactoryManager:GetLocationCoords()
    if aibrain_methodsGetThreatAtPosition(aiBrain,  position, testRings, true, threatType or 'Overall' ) > threatValue then
        return true
    end
    return false
end

function HaveLessThreatThanNearby( aiBrain, locationType, poolType, enemyType, rings )
    local pool = aibrain_methodsGetPlatoonUniquelyNamed(aiBrain, 'ArmyPool')
    local poolThreat = pool:GetPlatoonThreat( poolType, categories.ALLUNITS )
    local testRings = rings or 10
    local FactoryManager = aiBrain.BuilderManagers[locationType].FactoryManager
    if not FactoryManager then
        return false
    end
    local position = FactoryManager:GetLocationCoords()
    local enemyThreat = aibrain_methodsGetThreatAtPosition(aiBrain,  position, testRings, true, enemyType )
    if poolThreat < enemyThreat then
        return true
    end
    return false
end

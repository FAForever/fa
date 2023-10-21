--****************************************************************************
--**
--**  File     :  /lua/editor/UnitCountBuildConditions.lua
--**  Author(s): Dru Staltman, John Comes
--**
--**  Summary  : Generic AI Platoon Build Conditions
--**             Build conditions always return true or false
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local AIUtils = import("/lua/ai/aiutilities.lua")
local ScenarioFramework = import("/lua/scenarioframework.lua")
local ScenarioUtils = import("/lua/sim/scenarioutilities.lua")
local Utils = import("/lua/utilities.lua")

---@param aiBrain AIBrain
---@param numReq number
---@param category EntityCategory
---@param idleReq boolean
---@return boolean
function HaveEqualToUnitsWithCategory(aiBrain, numReq, category, idleReq)
    local numUnits
    local testCat = category
    if type(category) == 'string' then
        testCat = ParseEntityCategory(category)
    end
    if not idleReq then
        numUnits = aiBrain:GetCurrentUnits(testCat)
    else
        numUnits = table.getn(aiBrain:GetListOfUnits(testCat, true))
    end
    if numUnits == numReq then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param numReq number
---@param category EntityCategory
---@param idleReq boolean
---@return boolean
function HaveGreaterThanUnitsWithCategory(aiBrain, numReq, category, idleReq)
    local numUnits
    local testCat = category
    if type(category) == 'string' then
        testCat = ParseEntityCategory(category)
    end
    if not idleReq then
        numUnits = aiBrain:GetCurrentUnits(testCat)
    else
        numUnits = table.getn(aiBrain:GetListOfUnits(testCat, true))
    end
    if numUnits > numReq then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param numReq number
---@param category EntityCategory
---@param idleReq boolean
---@return boolean
function HaveLessThanUnitsWithCategory(aiBrain, numReq, category, idleReq)
    local numUnits
    local testCat = category
    if type(category) == 'string' then
        testCat = ParseEntityCategory(category)
    end
    if not idleReq then
        numUnits = aiBrain:GetCurrentUnits(testCat)
    else
        numUnits = table.getn(aiBrain:GetListOfUnits(testCat, true))
    end
    if numUnits < numReq then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param numReq number
---@param category EntityCategory
---@param area Area
---@return boolean
function HaveLessThanUnitsWithCategoryInArea(aiBrain, numReq, category, area)
    local numUnits = ScenarioFramework.NumCatUnitsInArea(category, ScenarioUtils.AreaToRect(area), aiBrain)
    if numUnits < numReq then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param baseName string
---@param category EntityCategory
---@param num number
---@return boolean
function NumUnitsLessNearBase(aiBrain, baseName, category, num)
    if aiBrain.BaseTemplates[baseName].Location == nil then
        return false
    else
        local unitList = aiBrain:GetUnitsAroundPoint(category,aiBrain.BaseTemplates[baseName].Location,aiBrain.BaseTemplates[baseName].Radius, 'Ally')
        local count = 0
        for i,unit in unitList do
            if unit:GetAIBrain() == aiBrain then
                count = count + 1
            end
        end
        if count < num then
            return true
        end
        return false
    end
end

---@param aiBrain AIBrain
---@param category1 EntityCategory
---@param category2 EntityCategory
---@return boolean
function HaveLessThanUnitComparison(aiBrain, category1, category2)
    local testCat1 = category1
    if type(category1) == 'string' then
        testCat1 = ParseEntityCategory(category1)
    end
    local testCat2 = category2
    if type(category2) == 'string' then
        testCat2 = ParseEntityCategory(category2)
    end
    local numUnits1 = aiBrain:GetCurrentUnits(testCat1)
    local numUnits2 = aiBrain:GetCurrentUnits(testCat2)
    if numUnits1 < numUnits2 then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param category1 EntityCategory
---@param category2 EntityCategory
---@return boolean
function HaveGreaterThanUnitComparison(aiBrain, category1, category2)
    local testCat1 = category1
    if type(category1) == 'string' then
        testCat1 = ParseEntityCategory(category1)
    end
    local testCat2 = category2
    if type(category2) == 'string' then
        testCat2 = ParseEntityCategory(category2)
    end
    local numUnits1 = aiBrain:GetCurrentUnits(testCat1)
    local numUnits2 = aiBrain:GetCurrentUnits(testCat2)
    if numUnits1 > numUnits2 then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param varName string
---@param category EntityCategory
---@return boolean
function HaveLessThanVarTableUnitsWithCategory(aiBrain, varName, category)
    local testCat = category
    if type(category) == 'string' then
        testCat = ParseEntityCategory(category)
    end
    local numUnits = aiBrain:GetCurrentUnits(testCat)
    if ScenarioInfo.VarTable[varName] then
        if numUnits < ScenarioInfo.VarTable[varName] then
            return true
        end
    end
    return false
end

---@param aiBrain AIBrain
---@param varName string
---@param category EntityCategory
---@return boolean
function HaveGreaterThanVarTableUnitsWithCategory(aiBrain, varName, category)
    local testCat = category
    if type(category) == 'string' then
        testCat = ParseEntityCategory(category)
    end
    local numUnits = aiBrain:GetCurrentUnits(testCat)
    if ScenarioInfo.VarTable[varName] then
        if numUnits > ScenarioInfo.VarTable[varName] then
            return true
        end
    end
    return false
end

---@param aiBrain AIBrain
---@param varName string
---@param category EntityCategory
---@param area string
---@return boolean
function HaveLessThanVarTableUnitsWithCategoryInArea(aiBrain, varName, category, area)
    local testCat = category
    if type(category) == 'string' then
        testCat = ParseEntityCategory(category)
    end
    local numUnits = ScenarioFramework.NumCatUnitsInArea(testCat, ScenarioUtils.AreaToRect(area), aiBrain)
    if ScenarioInfo.VarTable[varName] then
        if numUnits < ScenarioInfo.VarTable[varName] then
            return true
        end
    end
    return false
end

---@param aiBrain AIBrain
---@param varName string
---@param category EntityCategory
---@param area string
---@return boolean
function HaveGreaterThanVarTableUnitsWithCategoryInArea(aiBrain, varName, category, area)
    local testCat = category
    if type(category) == 'string' then
        testCat = ParseEntityCategory(category)
    end
    local numUnits = ScenarioFramework.NumCatUnitsInArea(testCat, ScenarioUtils.AreaToRect(area), aiBrain)
    if ScenarioInfo.VarTable[varName] then
        if numUnits > ScenarioInfo.VarTable[varName] then
            return true
        end
    end
    return false
end

---@param aiBrain AIBrain
---@param numReq number
---@param category EntityCategory
---@param constructionCat EntityCategory
---@return boolean
function HaveGreaterThanUnitsInCategoryBeingBuilt(aiBrain, numReq, category, constructionCat)
    local cat = category
    if type(category) == 'string' then
        cat = ParseEntityCategory(category)
    end

    local consCat = constructionCat
    if consCat and type(consCat) == 'string' then
        consCat = ParseEntityCategory(constructionCat)
    end

    local numUnits
    if consCat then
        numUnits = aiBrain:NumCurrentlyBuilding(cat, cat + categories.CONSTRUCTION + consCat)
    else
        numUnits = aiBrain:NumCurrentlyBuilding(cat, cat + categories.CONSTRUCTION)
    end

    if numUnits > numReq then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param numunits number
---@param category EntityCategory
---@return boolean
function HaveLessThanUnitsInCategoryBeingBuilt(aiBrain, numunits, category)
    --DUNCAN - rewritten, credit to Sorian
    if type(category) == 'string' then
        category = ParseEntityCategory(category)
    end

    local unitsBuilding = aiBrain:GetListOfUnits(categories.CONSTRUCTION, false)
    local numBuilding = 0
    for unitNum, unit in unitsBuilding do
        if not unit:BeenDestroyed() and unit:IsUnitState('Building') then
            local buildingUnit = unit.UnitBeingBuilt
            if buildingUnit and not buildingUnit.Dead and EntityCategoryContains(category, buildingUnit) then
                numBuilding = numBuilding + 1
            end
        end
        --DUNCAN - added to pick up engineers that havent started building yet... does it work?
        if not unit:BeenDestroyed() and not unit:IsUnitState('Building') then
            local buildingUnit = unit.UnitBeingBuilt
            if buildingUnit and not buildingUnit.Dead and EntityCategoryContains(category, buildingUnit) then
                --LOG('Engi building but not in building state...')
                numBuilding = numBuilding + 1
            end
        end
        if numunits <= numBuilding then
            return false
        end
    end
    if numunits > numBuilding then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param markerType string
---@param markerRadius number
---@param locationType string
---@param locationRadius number
---@param unitCount number
---@param unitCategory string
---@param threatMin number
---@param threatMax number
---@param threatRings number
---@param threatType string
---@return boolean
function HaveLessThanUnitsAroundMarkerCategory(aiBrain, markerType, markerRadius, locationType, locationRadius,unitCount, unitCategory, threatMin, threatMax, threatRings, threatType)
    local pos = aiBrain:PBMGetLocationCoords(locationType)
    if not pos then
        return false
    end
    local positions = AIUtils.AIGetMarkersAroundLocation(aiBrain, markerType, pos, locationType, threatMin, threatMax, threatRings, threatType)
    for k,v in positions do
        local unitTotal = table.getn(AIUtils.GetOwnUnitsAroundPoint(aiBrain, ParseEntityCategory(unitCategory), v.Position, markerRadius, threatMin,
            threatMax, threatRings, threatType))
        if unitTotal < unitCount then
            return true
        end
    end
    return false
end

---@param aiBrain AIBrain
---@param locationType string
---@param locationRadius number
---@param threatMin number
---@param threatMax number
---@param threatRings number
---@param threatType string
---@return boolean
function StartLocationNeedsEngineer(aiBrain, locationType, locationRadius, threatMin, threatMax, threatRings, threatType)
    local pos, name = AIUtils.AIFindStartLocationNeedsEngineer(aiBrain, locationType, locationRadius, threatMin, threatMax, threatRings, threatType)
    if pos then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param locationType string
---@param locationRadius number
---@param threatMin number
---@param threatMax number
---@param threatRings number
---@param threatType string
---@return boolean
function StartLocationsFull(aiBrain, locationType, locationRadius, threatMin, threatMax, threatRings, threatType)
    local pos, name = AIUtils.AIFindStartLocationNeedsEngineer(aiBrain, locationType, locationRadius, threatMin, threatMax, threatRings, threatType)
    if not pos then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param locationType string
---@param locationRadius number
---@param threatMin number
---@param threatMax number
---@param threatRings number
---@param threatType string
---@return boolean
function ExpansionAreaNeedsEngineer(aiBrain, locationType, locationRadius, threatMin, threatMax, threatRings, threatType)
    local pos, name = AIUtils.AIFindExpansionAreaNeedsEngineer(aiBrain, locationType, locationRadius, threatMin, threatMax, threatRings, threatType)
    if pos then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param locationType string
---@param locationRadius number
---@param threatMin number
---@param threatMax number
---@param threatRings number
---@param threatType string
---@return boolean
function NavalAreaNeedsEngineer(aiBrain, locationType, locationRadius, threatMin, threatMax, threatRings, threatType)
    local pos, name = AIUtils.AIFindNavalAreaNeedsEngineer(aiBrain, locationType, locationRadius, threatMin, threatMax, threatRings, threatType)
    if pos then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param locationType string
---@param locationRadius number
---@param threatMin number
---@param threatMax number
---@param threatRings number
---@param threatType string
---@return boolean
function NavalAreasFull(aiBrain, locationType, locationRadius, threatMin, threatMax, threatRings, threatType)
    local pos, name = AIUtils.AIFindNavalAreaNeedsEngineer(aiBrain, locationType, locationRadius, threatMin, threatMax, threatRings, threatType)
    if not pos then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param locationType string
---@param locationRadius number
---@param category EntityCategory
---@param markerRadius number
---@param unitMax number
---@param threatMin number
---@param threatMax number
---@param threatRings number
---@param threatType string
---@return boolean
function DefensivePointNeedsStructure(aiBrain, locationType, locationRadius, category, markerRadius, unitMax, threatMin, threatMax, threatRings, threatType)
    local pos, name = AIUtils.AIFindDefensivePointNeedsStructure(aiBrain, locationType, locationRadius, category, markerRadius, unitMax, threatMin, threatMax, threatRings, threatType)
    if pos then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param locationType string
---@param locationRadius number
---@param category EntityCategory
---@param markerRadius number
---@param unitMax number
---@param threatMin number 
---@param threatMax number 
---@param threatRings number
---@param threatType string
---@return boolean
function NavalDefensivePointNeedsStructure(aiBrain, locationType, locationRadius, category, markerRadius, unitMax, threatMin, threatMax, threatRings, threatType)
    local pos, name = AIUtils.AIFindNavalDefensivePointNeedsStructure(aiBrain, locationType, locationRadius, category, markerRadius, unitMax, threatMin, threatMax, threatRings, threatType)
    if pos then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param locationType string
---@param locationRadius number
---@param unitCount number
---@param unitCategory EntityCategory
---@param threatMin number
---@param threatMax number
---@param threatRings number
---@param threatType string
---@return boolean
function HaveAreaWithUnitsFewWalls(aiBrain, locationType, locationRadius, unitCount, unitCategory, threatMin, threatMax, threatRings, threatType)
    local pos = aiBrain:PBMGetLocationCoords(locationType)
    if not pos then
        return false
    end
    local positions = {}
    if aiBrain.HasPlatoonList then
        for k,v in aiBrain.PBM.Locations do
            if v.LocationType ~= locationType and Utils.XZDistanceTwoVectors(pos, v.Location) <= locationRadius then
                table.insert(positions, v.Location)
            end
        end
    elseif aiBrain.BuilderManagers[locationType] then
        table.insert(positions, aiBrain.BuilderManagers[locationType].FactoryManager:GetLocationCoords())
    end
    local otherPos = AIUtils.AIGetMarkersAroundLocation(aiBrain, 'Defensive Point', pos, locationRadius, threatMin, threatMax, threatRings, threatType)
    for k,v in otherPos do
        table.insert(positions, v.Position)
    end
    for k,v in positions do
        local unitTotal = table.getn(AIUtils.GetOwnUnitsAroundPoint(aiBrain, ParseEntityCategory('DEFENSE'), v, 30, threatMin,
            threatMax, threatRings, threatType))
        if unitTotal > unitCount then
            if aiBrain:GetNumUnitsAroundPoint(categories.WALL, v, 30, 'Ally') < 15 then
                return true
            end
        end
    end
    return false
end

---@param aiBrain AIBrain
---@param greater boolean
---@param numReq number
---@param category EntityCategory
---@param alliance string
---@return boolean
function HaveUnitsWithCategoryAndAlliance(aiBrain, greater, numReq, category, alliance)
    local testCat = category
    if type(category) == 'string' then
        testCat = ParseEntityCategory(category)
    end
    local numUnits = aiBrain:GetNumUnitsAroundPoint(testCat, Vector(0,0,0), 100000, alliance)
    if numUnits > numReq and greater then
        return true
    elseif numUnits < numReq and not greater then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param locationType string
---@return boolean
function EngineersNeedGuard(aiBrain, locationType)
    local units = aiBrain:GetListOfUnits(categories.ENGINEER - categories.COMMAND, false)
    for k,v in units do
        if v.NeedGuard and not v.BeingGuarded then
            return true
        end
    end
    return false
end

-- =========================================== --
--     Builder Manager Generic Unit Counts
-- =========================================== --

---@param aiBrain AIBrain
---@param locationType string
---@param unitCount number
---@param unitCategory EntityCategory
---@param compareType string
---@return boolean
function HaveUnitComparisonAtLocation(aiBrain, locationType, unitCount, unitCategory, compareType)
    local engineerManager = aiBrain.BuilderManagers[locationType].EngineerManager
    local testCat = unitCategory
    if type(unitCategory) == 'string' then
        testCat = ParseEntityCategory(unitCategory)
    end
    if not engineerManager then
        WARN('*AI WARNING: HaveUnitComparisonAtLocation - Invalid location - ' .. locationType)
        return false
    end
    local numUnits = table.getn(AIUtils.GetOwnUnitsAroundPoint(aiBrain, testCat, engineerManager:GetLocationCoords(), engineerManager.Radius))
    return CompareBody(numUnits, unitCount, compareType)
end

---@param aiBrain AIBrain
---@param locationType string
---@param unitCount number
---@param unitCategory EntityCategory
---@return boolean
function UnitsLessAtLocation(aiBrain, locationType, unitCount, unitCategory)
    return HaveUnitComparisonAtLocation(aiBrain, locationType, unitCount, unitCategory, '<')
end

---@param aiBrain AIBrain
---@param locationType string
---@param unitCount number
---@param unitCategory EntityCategory
---@return boolean
function UnitsGreaterAtLocation(aiBrain, locationType, unitCount, unitCategory)
    return HaveUnitComparisonAtLocation(aiBrain, locationType, unitCount, unitCategory, '>')
end

-- ============================================ --
--     Builder Manager Location Pool Counts
-- ============================================ --

---@param aiBrain AIBrain
---@param locationType string
---@param unitCount number
---@param unitCategory EntityCategory
---@param compareType string
---@return boolean
function HavePoolUnitComparisonAtLocation(aiBrain, locationType, unitCount, unitCategory, compareType)
    local engineerManager = aiBrain.BuilderManagers[locationType].EngineerManager
    local testCat = unitCategory
    if type(unitCategory) == 'string' then
        testCat = ParseEntityCategory(unitCategory)
    end
    if not engineerManager then
        WARN('*AI WARNING: HavePoolUnitComparisonAtLocation - Invalid location - ' .. locationType)
        return false
    end
    local poolPlatoon = aiBrain:GetPlatoonUniquelyNamed('ArmyPool')
    local numUnits = poolPlatoon:GetNumCategoryUnits(testCat, engineerManager:GetLocationCoords(), engineerManager.Radius)
    return CompareBody(numUnits, unitCount, compareType)
end

---@param aiBrain AIBrain
---@param locationType string
---@param unitCount number
---@param unitCategory EntityCategory
---@return boolean
function PoolLessAtLocation(aiBrain, locationType, unitCount, unitCategory)
    return HavePoolUnitComparisonAtLocation(aiBrain, locationType, unitCount, unitCategory, '<')
end

---@param aiBrain AIBrain
---@param locationType string
---@param unitCount number
---@param unitCategory EntityCategory
---@return boolean
function PoolGreaterAtLocation(aiBrain, locationType, unitCount, unitCategory)
    return HavePoolUnitComparisonAtLocation(aiBrain, locationType, unitCount, unitCategory, '>')
end

-- ======================================= --
--     Builder Manager Engineer Counts
-- ======================================= --

---@param aiBrain AIBrain
---@param locationType string
---@param unitCount number
---@param unitCategory EntityCategory
---@param compareType string
---@return boolean
function EngineerComparisonAtLocation(aiBrain, locationType, unitCount, unitCategory, compareType)
    local engineerManager = aiBrain.BuilderManagers[locationType].EngineerManager
    local testCat = unitCategory
    if type(unitCategory) == 'string' then
        testCat = ParseEntityCategory(unitCategory)
    end
    if not engineerManager then
        WARN('*AI WARNING: EngineerComparisonAtLocation - Invalid location - ' .. locationType)
        return false
    end
    local numUnits = engineerManager:GetNumCategoryUnits('Engineers', testCat)
    return CompareBody(numUnits, unitCount, compareType)
end

---@param aiBrain AIBrain
---@param locationType string
---@param unitCount number
---@param unitCategory EntityCategory
---@return boolean
function EngineerLessAtLocation(aiBrain, locationType, unitCount, unitCategory)
    return EngineerComparisonAtLocation(aiBrain, locationType, unitCount, unitCategory, '<')
end

---@param aiBrain AIBrain
---@param locationType string
---@param unitCount number
---@param unitCategory EntityCategory
---@return boolean
function EngineerGreaterAtLocation(aiBrain, locationType, unitCount, unitCategory)
    return EngineerComparisonAtLocation(aiBrain, locationType, unitCount, unitCategory, '>')
end

-- ====================================== --
--     Factory Manager Factory Counts
-- ====================================== --

---@param aiBrain AIBrain
---@param locationType string
---@param unitCount number
---@param unitCategory EntityCategory
---@param compareType string
---@return boolean
function FactoryComparisonAtLocation(aiBrain, locationType, unitCount, unitCategory, compareType)
    local factoryManager = aiBrain.BuilderManagers[locationType].FactoryManager
    local testCat = unitCategory
    if type(unitCategory) == 'string' then
        testCat = ParseEntityCategory(unitCategory)
    end
    if not factoryManager then
        WARN('*AI WARNING: FactoryComparisonAtLocation - Invalid location - ' .. locationType)
        return false
    end
    local numUnits = factoryManager:GetNumCategoryFactories(testCat)
    return CompareBody(numUnits, unitCount, compareType)
end

---@param aiBrain AIBrain
---@param locationType string
---@param unitCount number
---@param unitCategory EntityCategory
---@return boolean
function FactoryLessAtLocation(aiBrain, locationType, unitCount, unitCategory)
    return FactoryComparisonAtLocation(aiBrain, locationType, unitCount, unitCategory, '<')
end

---@param aiBrain AIBrain
---@param locationType string
---@param unitCount number
---@param unitCategory EntityCategory
---@return boolean
function FactoryGreaterAtLocation(aiBrain, locationType, unitCount, unitCategory)
    return FactoryComparisonAtLocation(aiBrain, locationType, unitCount, unitCategory, '>')
end

-- ====================================== --
--     Factory Manager Factory Ratios
-- ====================================== --

---@param aiBrain AIBrain
---@param locationType string
---@param unitCategory EntityCategory
---@param unitCategory2 EntityCategory
---@param compareType string
---@return boolean
function FactoryRatioComparisonAtLocation(aiBrain, locationType, unitCategory, unitCategory2, compareType)
    local factoryManager = aiBrain.BuilderManagers[locationType].FactoryManager
    local testCat = unitCategory
    if type(unitCategory) == 'string' then
        testCat = ParseEntityCategory(unitCategory)
    end
    local testCat2 = unitCategory2
    if type(unitCategory2) == 'string' then
        testCat2 = ParseEntityCategory(unitCategory2)
    end
    if not factoryManager then
        WARN('*AI WARNING: FactoryRatioComparisonAtLocation - Invalid location - ' .. locationType)
        return false
    end
    local numUnits = factoryManager:GetNumCategoryFactories(testCat)
    local numUnits2 = factoryManager:GetNumCategoryFactories(testCat2)
    return CompareBody(numUnits, numUnits2, compareType)
end

---@param aiBrain AIBrain
---@param locationType string
---@param unitCategory EntityCategory
---@param unitCategory2 EntityCategory
---@return boolean
function FactoryRatioLessAtLocation(aiBrain, locationType, unitCategory, unitCategory2)
    return FactoryRatioComparisonAtLocation(aiBrain, locationType, unitCategory, unitCategory2, '<')
end

---@param aiBrain AIBrain
---@param locationType string
---@param unitCategory EntityCategory
---@param unitCategory2 EntityCategory
---@return boolean
function FactoryRatioGreaterAtLocation(aiBrain, locationType, unitCategory, unitCategory2)
    return FactoryRatioComparisonAtLocation(aiBrain, locationType, unitCategory, unitCategory2, '>')
end

-- ============================== --
--     Manager Builing Counts
-- ============================== --

---@param aiBrain AIBrain
---@param locationType string
---@param unitCount number
---@param unitCategory EntityCategory
---@param compareType string
---@param builderCat EntityCategory
---@return boolean
function LocationBuildingComparison(aiBrain, locationType, unitCount, unitCategory, compareType, builderCat)
    local platoonFormManager = aiBrain.BuilderManagers[locationType].PlatoonFormManager
    local testCat = unitCategory
    if type(unitCategory) == 'string' then
        testCat = ParseEntityCategory(unitCategory)
    end
    local builderTestCat = builderCat
    if type(builderTestCat) == 'string' then
        builderTestCat = ParseEntityCategory(builderTestCat)
    end
    if not platoonFormManager then
        WARN('*AI WARNING: LocationBuildingComparison - Invalid location - ' .. locationType)
        return false
    end
    local numUnits = table.getn(platoonFormManager:GetUnitsBeingBuilt(testCat, builderTestCat or categories.ALLUNITS))
    return CompareBody(numUnits, unitCount, compareType)
end

---@param aiBrain AIBrain
---@param locationType string
---@param unitCount number
---@param unitCategory EntityCategory
---@param builderCat EntityCategory
---@return boolean
function BuildingLessAtLocation(aiBrain, locationType, unitCount, unitCategory, builderCat)
    return LocationBuildingComparison(aiBrain, locationType, unitCount, unitCategory, '<', builderCat)
end

---@param aiBrain AIBrain
---@param locationType string
---@param unitCount number
---@param unitCategory EntityCategory
---@param builderCat EntityCategory
---@return boolean
function BuildingGreaterAtLocation(aiBrain, locationType, unitCount, unitCategory, builderCat)
    return LocationBuildingComparison(aiBrain, locationType, unitCount, unitCategory, '>', builderCat)
end

-- ============================================ --
--     Factory Manager Building Unit Counts
-- ============================================ --

---@param aiBrain AIBrain
---@param locationType string
---@param unitCount number
---@param unitCategory EntityCategory
---@param compareType string
---@param facCat EntityCategory
---@return boolean
function LocationFactoriesBuildingComparison(aiBrain, locationType, unitCount, unitCategory, compareType, facCat)
    local factoryManager = aiBrain.BuilderManagers[locationType].FactoryManager
    local testCat = unitCategory
    if type(unitCategory) == 'string' then
        testCat = ParseEntityCategory(unitCategory)
    end
    if not factoryManager then
        WARN('*AI WARNING: LocationFactoriesBuildingComparison - Invalid location - ' .. locationType)
        return false
    end

    local testFac = facCat or categories.ALLUNITS
    if type(facCat) == 'string' then
        testFac = ParseEntityCategory(facCat)
    end

    local numUnits = factoryManager:GetNumCategoryBeingBuilt(testCat, testFac)
    return CompareBody(numUnits, unitCount, compareType)
end

---@param aiBrain AIBrain
---@param locationType string
---@param unitCount number
---@param unitCategory EntityCategory
---@param facCat EntityCategory
---@return boolean
function LocationFactoriesBuildingLess(aiBrain, locationType, unitCount, unitCategory, facCat)
    return LocationFactoriesBuildingComparison(aiBrain, locationType, unitCount, unitCategory, '<', facCat)
end

---@param aiBrain AIBrain
---@param locationType string
---@param unitCount number
---@param unitCategory EntityCategory
---@param facCat EntityCategory
---@return boolean
function LocationFactoriesBuildingGreater(aiBrain, locationType, unitCount, unitCategory, facCat)
    return LocationFactoriesBuildingComparison(aiBrain, locationType, unitCount, unitCategory, '>', facCat)
end

-- ============================================= --
--     Engineer Manager Building Unit Counts
-- ============================================= --

---@param aiBrain AIBrain
---@param locationType string
---@param unitCount number
---@param unitCategory EntityCategory
---@param compareType string
---@param engCat EntityCategory
---@return boolean
function LocationEngineersBuildingComparison(aiBrain, locationType, unitCount, unitCategory, compareType, engCat)
    local engineerManager = aiBrain.BuilderManagers[locationType].EngineerManager
    local testCat = unitCategory
    if type(unitCategory) == 'string' then
        testCat = ParseEntityCategory(unitCategory)
    end
    if not engineerManager then
        WARN('*AI WARNING: LocationEngineersBuildingComparison - Invalid location - ' .. locationType)
        return false
    end

    local engCat = engCat or categories.ALLUNITS
    if type(engCat) == 'string' then
        engCat = ParseEntityCategory(engCat)
    end

    local numUnits = engineerManager:GetNumCategoryBeingBuilt(testCat, engCat)
    return CompareBody(numUnits, unitCount, compareType)
end

---@param aiBrain AIBrain
---@param locationType string
---@param unitCount number
---@param unitCategory EntityCategory
---@param engCat EntityCategory
---@return boolean
function LocationEngineersBuildingLess(aiBrain, locationType, unitCount, unitCategory, engCat)
    return LocationEngineersBuildingComparison(aiBrain, locationType, unitCount, unitCategory, '<', engCat)
end

---@param aiBrain AIBrain
---@param locationType string
---@param unitCount number
---@param unitCategory EntityCategory
---@param engCat EntityCategory
---@return boolean
function LocationEngineersBuildingGreater(aiBrain, locationType, unitCount, unitCategory, engCat)
    return LocationEngineersBuildingComparison(aiBrain, locationType, unitCount, unitCategory, '>', engCat)
end

-- ===================================================== --
--     Engineers Wanting Assistance Build Conditions
-- ===================================================== --

---@param aiBrain AIBrain
---@param locationType string
---@param unitCategory EntityCategory
---@param compareType string
---@param engCat EntityCategory
---@return boolean
function LocationEngineersBuildingAssistanceComparison(aiBrain, locationType, unitCategory, compareType, engCat)
    local engineerManager = aiBrain.BuilderManagers[locationType].EngineerManager
    local testCat = unitCategory
    if type(unitCategory) == 'string' then
        testCat = ParseEntityCategory(unitCategory)
    end
    if not engineerManager then
        WARN('*AI WARNING: LocationEngineersBuildingAssistanceComparison - Invalid location - ' .. locationType)
        return false
    end

    local engCat = engCat or categories.ALLUNITS
    if type(engCat) == 'string' then
        engCat = ParseEntityCategory(engCat)
    end

    local numUnits = table.getn(engineerManager:GetEngineersWantingAssistance(testCat, engCat))
    return CompareBody(numUnits, 0, compareType)
end

---@param aiBrain AIBrain
---@param locationType string
---@param unitCount number
---@param unitCategory EntityCategory
---@param engCat EntityCategory
---@return boolean
function LocationEngineersBuildingAssistanceLess(aiBrain, locationType, unitCount, unitCategory, engCat)
    return LocationEngineersBuildingAssistanceComparison(aiBrain, locationType, unitCategory, '<', engCat)
end

---@param aiBrain AIBrain
---@param locationType string
---@param unitCount number
---@param unitCategory EntityCategory
---@param engCat EntityCategory
---@return boolean
function LocationEngineersBuildingAssistanceGreater(aiBrain, locationType, unitCount, unitCategory, engCat)
    return LocationEngineersBuildingAssistanceComparison(aiBrain, locationType, unitCategory, '>', engCat)
end

-- ==================================================== --
--     Factory Manager Check Maximum Factory Number
-- ==================================================== --

---@param aiBrain AIBrain
---@param locationType string
---@param factoryType string
---@return boolean
function FactoryCapCheck(aiBrain, locationType, factoryType)
    local catCheck = false
    if factoryType == 'Land' then
        catCheck = categories.LAND * categories.FACTORY
    elseif factoryType == 'Air' then
        catCheck = categories.AIR * categories.FACTORY
    elseif factoryType == 'Sea' then
        catCheck = categories.NAVAL * categories.FACTORY
    elseif factoryType == 'Gate' then
        catCheck = categories.GATE
    else
        WARN('*AI WARNING: Invalid factorytype - ' .. factoryType)
        return false
    end
    local factoryManager = aiBrain.BuilderManagers[locationType].FactoryManager
    if not factoryManager then
        WARN('*AI WARNING: FactoryCapCheck - Invalid location - ' .. locationType)
        return false
    end
    local numUnits = factoryManager:GetNumCategoryFactories(catCheck)
    numUnits = numUnits + aiBrain:GetEngineerManagerUnitsBeingBuilt(catCheck)

    if numUnits < aiBrain.BuilderManagers[locationType].BaseSettings.FactoryCount[factoryType] then
        return true
    end
    return false
end

-- ===================================================== --
--     Engineer Manager Check Maximum Factory Number
-- ===================================================== --

---@param aiBrain AIBrain
---@param locationType string
---@param techLevel number
---@return boolean
function EngineerCapCheck(aiBrain, locationType, techLevel)
    local catCheck = false
    if techLevel == 'Tech1' then
        catCheck = categories.TECH1
    elseif techLevel == 'Tech2' then
        catCheck = categories.TECH2
    elseif techLevel == 'Tech3' then
        catCheck = categories.TECH3
    elseif techLevel == 'SCU' then
        catCheck = categories.SUBCOMMANDER
    else
        WARN('*AI WARNING: Invalid techLevel - ' .. techLevel)
        return false
    end
    local engineerManager = aiBrain.BuilderManagers[locationType].EngineerManager
    if not engineerManager then
        WARN('*AI WARNING: EngineerCapCheck - Invalid location - ' .. locationType)
        return false
    end
    local numUnits = engineerManager:GetNumCategoryUnits('Engineers', catCheck)
    if numUnits < aiBrain.BuilderManagers[locationType].BaseSettings.EngineerCount[techLevel] then
        return true
    end
    return false
end

-- ======================================================================================= --
--     Adjacency Check - Ensures a building category can have something adjacent to it
-- ======================================================================================= --

---@param aiBrain AIBrain
---@param locationType string
---@param category EntityCategory
---@param radius number
---@param testUnit Unit
---@return boolean
function AdjacencyCheck(aiBrain, locationType, category, radius, testUnit)
    local factoryManager = aiBrain.BuilderManagers[locationType].FactoryManager
    if not factoryManager then
        WARN('*AI WARNING: AdjacencyCheck - Invalid location - ' .. locationType)
        return false
    end

    local testCat = category
    if type(category) == 'string' then
        testCat = ParseEntityCategory(category)
    end

    local reference  = AIUtils.GetOwnUnitsAroundPoint(aiBrain, testCat, factoryManager:GetLocationCoords(), radius)
    if not reference or table.empty(reference) then
        return false
    end

    local template = {}
    local unitSize = aiBrain:GetUnitBlueprint(testUnit).Physics
    for k,v in reference do
        if not v.Dead then
            local targetSize = v:GetBlueprint().Physics
            local targetPos = v:GetPosition()
            targetPos[1] = targetPos[1] - (targetSize.SkirtSizeX/2)
            targetPos[3] = targetPos[3] - (targetSize.SkirtSizeZ/2)
            -- Top/bottom of unit
            for i=0,((targetSize.SkirtSizeX/2)-1) do
                local testPos = { targetPos[1] + 1 + (i * 2), targetPos[3]-(unitSize.SkirtSizeZ/2), 0 }
                local testPos2 = { targetPos[1] + 1 + (i * 2), targetPos[3]+targetSize.SkirtSizeZ+(unitSize.SkirtSizeZ/2), 0 }
                table.insert(template, testPos)
                table.insert(template, testPos2)
            end
            -- Sides of unit
            for i=0,((targetSize.SkirtSizeZ/2)-1) do
                local testPos = { targetPos[1]+targetSize.SkirtSizeX + (unitSize.SkirtSizeX/2), targetPos[3] + 1 + (i * 2), 0 }
                local testPos2 = { targetPos[1]-(unitSize.SkirtSizeX/2), targetPos[3] + 1 + (i*2), 0 }
                table.insert(template, testPos)
                table.insert(template, testPos2)
            end
        end
    end

    for k,v in template do
        if aiBrain:CanBuildStructureAt(testUnit, { v[1], 0, v[2] }) then
            return true
        end
    end
    return false
end

-- ================== --
--     Unit Ratio
-- ================== --

---@param aiBrain AIBrain
---@param ratio number
---@param categoryOne EntityCategory
---@param compareType string
---@param categoryTwo EntityCategory
---@return unknown
function HaveUnitRatio(aiBrain, ratio, categoryOne, compareType, categoryTwo)
    local testCatOne = categoryOne
    if type(testCatOne) == 'string' then
        testCatOne = ParseEntityCategory(testCatOne)
    end
    local numOne = aiBrain:GetCurrentUnits(testCatOne)

    local testCatTwo = categoryTwo
    if type(testCatTwo) == 'string' then
        testCatTwo = ParseEntityCategory(testCatTwo)
    end
    local numTwo = aiBrain:GetCurrentUnits(testCatTwo)

    return CompareBody(numOne / numTwo, ratio, compareType)
end

---@param aiBrain AIBrain
---@param ratio number
---@param categoryOne EntityCategory
---@param categoryTwo EntityCategory
---@return boolean
function HaveUnitRatioGreaterThan(aiBrain, ratio, categoryOne, categoryTwo)
    local numOne = aiBrain:GetCurrentUnits(categoryOne)
    local numTwo = aiBrain:GetCurrentUnits(categoryTwo)
    if numOne / numTwo < ratio then
        return true
    end
    return false
end

-- ================ --
--     Unit Cap
-- ================ --

---@param aiBrain AIBrain
---@param percent number
---@return boolean
function UnitCapCheckGreater(aiBrain, percent)
    local currentCount = GetArmyUnitCostTotal(aiBrain:GetArmyIndex())
    local cap = GetArmyUnitCap(aiBrain:GetArmyIndex())
    if (currentCount / cap) > percent then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param percent number
---@return boolean
function UnitCapCheckLess(aiBrain, percent)
    local currentCount = GetArmyUnitCostTotal(aiBrain:GetArmyIndex())
    local cap = GetArmyUnitCap(aiBrain:GetArmyIndex())
    if (currentCount / cap) < percent then
        return true
    end
    return false
end

-- =================== --
--     UNIT RANGES     --
-- =================== --

---@param aiBrain AIBrain
---@param locationType string
---@param unitType string
---@param category EntityCategory
---@param factionIndex number
---@return boolean
function CheckUnitRange(aiBrain, locationType, unitType, category, factionIndex)

    -- Find the unit's blueprint
    local template = import("/lua/buildingtemplates.lua").BuildingTemplates[factionIndex or aiBrain:GetFactionIndex()]
    local buildingId = false
    for k,v in template do
        if v[1] == unitType then
            buildingId = v[2]
            break
        end
    end
    if not buildingId then
        WARN('*AI ERROR: Invalid building type - ' .. unitType)
        return false
    end

    local bp = GetUnitBlueprintByName(buildingId)
    if not bp.Economy.BuildTime or not bp.Economy.BuildCostMass then
        WARN('*AI ERROR: Unit for EconomyCheckStructure is missing blueprint values - ' .. unitType)
        return false
    end

    local range = false
    for k,v in bp.Weapon do
        if not range or v.MaxRadius > range then
            range = v.MaxRadius
        end
    end
    if not range then
        WARN('*AI ERROR: No MaxRadius for unit type - ' .. unitType)
        return false
    end

    local basePosition = aiBrain:GetLocationPosition(locationType)

    -- Check around basePosition for StructureThreat
    local unit = AIUtils.AIFindBrainTargetAroundPoint(aiBrain, basePosition, range, category)

    if unit then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param unitCategory EntityCategory
---@param compareType string
---@param large any
---@param small any
---@param naval any
---@return any
function UnitToExpansionsValue(aiBrain, unitCategory, compareType, large, small, naval)
    local needCount = aiBrain:GetManagerCount('Start Location') * large

    needCount = needCount + (aiBrain:GetManagerCount('Expansion Area') * small)

    needCount = needCount + (aiBrain:GetManagerCount('Naval Area') * naval)

    local testCat = unitCategory
    if type(testCat) == 'string' then
        testCat = ParseEntityCategory(unitCategory)
    end
    local unitCount = aiBrain:GetCurrentUnits(testCat)

    return CompareBody(unitCount, needCount, compareType)
end

---@param aiBrain AIBrain
---@param unitCategory EntityCategory
---@param large any
---@param small any
---@param naval any
---@return any
function UnitsGreaterThanExpansionValue(aiBrain, unitCategory, large, small, naval)
    return UnitToExpansionsValue(aiBrain, unitCategory, '>=', large, small, naval)
end

---comment
---@param aiBrain AIBrain
---@return any
function ExpansionBaseCheck(aiBrain)
    -- Removed automatic setting of Land-Expasions-allowed. We have a Game-Option for this.
    local checkNum = tonumber(ScenarioInfo.Options.LandExpansionsAllowed) or 3
    return ExpansionBaseCount(aiBrain, '<', checkNum)
end

---comment
---@param aiBrain AIBrain
---@return any
function NavalBaseCheck(aiBrain)
    -- Removed automatic setting of naval-Expasions-allowed. We have a Game-Option for this.
    local checkNum = tonumber(ScenarioInfo.Options.NavalExpansionsAllowed) or 2
    return NavalBaseCount(aiBrain, '<', checkNum)
end

--DUNCAN - added to limit expansion bases.
---comment
---@param aiBrain AIBrain
---@param compareType string
---@param checkNum number
---@return any
function ExpansionBaseCount(aiBrain, compareType, checkNum)
       local expBaseCount = aiBrain:GetManagerCount('Start Location')
       expBaseCount = expBaseCount + aiBrain:GetManagerCount('Expansion Area')
       --LOG('*AI DEBUG: Expansion base count is ' .. expBaseCount .. ' checkNum is ' .. checkNum)
       if expBaseCount > checkNum + 1 then
            --LOG('*AI DEBUG: Expansion base count is ' .. expBaseCount .. ' checkNum is ' .. checkNum)
       end
       return CompareBody(expBaseCount, checkNum, compareType)
end

--- added to limit naval bases.
---@param aiBrain AIBrain
---@param compareType string
---@param checkNum number
---@return any
function NavalBaseCount(aiBrain, compareType, checkNum)
       local expBaseCount = aiBrain:GetManagerCount('Naval Area')
       --LOG('*AI DEBUG: Naval base count is ' .. expBaseCount .. ' checkNum is ' .. checkNum)
       return CompareBody(expBaseCount, checkNum, compareType)
end

---@param numOne number
---@param numTwo number
---@param compareType string
---@return boolean
function CompareBody(numOne, numTwo, compareType)
    if compareType == '>' then
        if numOne > numTwo then
            return true
        end
    elseif compareType == '<' then
        if numOne < numTwo then
            return true
        end
    elseif compareType == '>=' then
        if numOne >= numTwo then
            return true
        end
    elseif compareType == '<=' then
        if numOne <= numTwo then
            return true
        end
    else
        error('*AI ERROR: Invalid compare type: ' .. compareType)
        return false
    end
    return false
end

--- credit to Sorian.
---@param aiBrain AIBrain
---@param upgrade string
---@param has boolean
---@return boolean
function CmdrHasUpgrade(aiBrain, upgrade, has)
    local units = aiBrain:GetListOfUnits(categories.COMMAND, false)
    for k,v in units do
        if v:HasEnhancement(upgrade) and has then
            return true
        elseif not v:HasEnhancement(upgrade) and not has then
            return true
        end
    end
    return false
end

--- moved here from Markerbuildconditions so its evaluated instantly.
---@param aiBrain AIBrain
---@param locationType string
---@param radius number
---@param markerType string
---@param tMin number
---@param tMax number
---@param tRings number
---@param tType string
---@param maxUnits number
---@param unitCat EntityCategory
---@param markerRadius number
---@return boolean
function CanBuildFirebase(aiBrain, locationType, radius, markerType, tMin, tMax, tRings, tType, maxUnits, unitCat, markerRadius)
    local ref, refName = AIUtils.AIFindFirebaseLocation(aiBrain, locationType, radius, markerType, tMin, tMax, tRings, tType, maxUnits, unitCat, markerRadius)
    if not ref then
        return false
    end
    return true
end

--- added for guard unit AI
---@param aiBrain AIBrain
---@param category EntityCategory
---@return boolean
function UnitsNeedGuard(aiBrain, category)
    local testCat = category
    if type(category) == 'string' then
        testCat = ParseEntityCategory(category)
    end

    local units = aiBrain:GetListOfUnits(testCat  , false)
    for k,v in units do
        if not v.BeingAirGuarded and not v.BeingLandGuarded then
            return true
        end
    end

    return false
end

---@param aiBrain AIBrain
---@return boolean
function T4BuildingCheck(aiBrain)
    if aiBrain.T4Building then
        return false
    end
    return true
end

---@param aiBrain AIBrain
---@param locationtype string
---@return boolean
function DamagedStructuresInArea(aiBrain, locationtype)
    local engineerManager = aiBrain.BuilderManagers[locationtype].EngineerManager
    if not engineerManager then
        return false
    end
    local Structures = AIUtils.GetOwnUnitsAroundPoint(aiBrain, categories.STRUCTURE - (categories.TECH1 - categories.FACTORY), engineerManager:GetLocationCoords(), engineerManager.Radius)
    for k,v in Structures do
        if not v.Dead and v:GetHealthPercent() < .8 then
        --LOG('*AI DEBUG: DamagedStructuresInArea return true')
            return true
        end
    end
    --LOG('*AI DEBUG: DamagedStructuresInArea return false')
    return false
end

---@param aiBrain AIBrain
---@param locationType string
---@param category EntityCategory
---@return boolean
function UnfinishedUnits(aiBrain, locationType, category)
    local engineerManager = aiBrain.BuilderManagers[locationType].EngineerManager
    if not engineerManager then
        return false
    end
    local unfinished = aiBrain:GetUnitsAroundPoint(category, engineerManager:GetLocationCoords(), engineerManager.Radius, 'Ally')
    for num, unit in unfinished do
        local donePercent = unit:GetFractionComplete()
        if donePercent < 1 and GetGuards(aiBrain, unit) < 1 then
            return true
        end
    end
    return false
end

---@param aiBrain AIBrain
---@param Unit Unit
---@return number
function GetGuards(aiBrain, Unit)
    local engs = aiBrain:GetUnitsAroundPoint(categories.ENGINEER, Unit:GetPosition(), 10, 'Ally')
    local count = 0
    local UpgradesFrom = Unit:GetBlueprint().General.UpgradesFrom
    for k,v in engs do
        if v.UnitBeingBuilt == Unit then
            count = count + 1
        end
    end
    if UpgradesFrom and UpgradesFrom != 'none' then -- Used to filter out upgrading units
        local oldCat = ParseEntityCategory(UpgradesFrom)
        local oldUnit = aiBrain:GetUnitsAroundPoint(oldCat, Unit:GetPosition(), 0, 'Ally')
        if oldUnit then
            count = count + 1
        end
    end
    return count
end

--- Buildcondition to limit the number of factories 
---@param aiBrain AIBrain
---@param locationType string
---@param unitCategory EntityCategory
---@param pathType string
---@param unitCount number
---@return boolean
function ForcePathLimit(aiBrain, locationType, unitCategory, pathType, unitCount)
    local currentEnemy = aiBrain:GetCurrentEnemy()
    if not currentEnemy then
        return true
    end
    local enemyIndex = aiBrain:GetCurrentEnemy():GetArmyIndex()
    local selfIndex = aiBrain:GetArmyIndex()
    if aiBrain.CanPathToEnemy[selfIndex][enemyIndex][locationType] ~= pathType then
        local factoryManager = aiBrain.BuilderManagers[locationType].FactoryManager
        local testCat = unitCategory
        if not factoryManager then
            WARN('*AI WARNING: FactoryComparisonAtLocation - Invalid location - ' .. locationType)
            return false
        end
        if factoryManager.LocationActive then
            local numUnits = factoryManager:GetNumCategoryFactories(testCat) or 0
            if numUnits > unitCount then
                return false
            end
            local unitsBuilding = aiBrain:GetListOfUnits(categories.CONSTRUCTION, false)
            for _, unit in unitsBuilding do
                if not unit:BeenDestroyed() and unit:IsUnitState('Building') then
                    local buildingUnit = unit.UnitBeingBuilt
                    if buildingUnit and not buildingUnit:BeenDestroyed() and EntityCategoryContains(unitCategory, buildingUnit) then
                        numUnits = numUnits + 1
                    end
                end
            end
            if numUnits > unitCount then
                return false
            end
        end
    end
    return true
end

--- Buildcondition to decide if radars should upgrade based on other radar locations.
---@param aiBrain AIBrain
---@param locationType string
---@param radarTech string
---@return boolean
function ShouldUpgradeRadar(aiBrain, locationType, radarTech)

    -- loop over radars that are one tech higher
    local basePos = aiBrain.BuilderManagers[locationType].Position
    local otherRadars = aiBrain.Radars[radarTech]
    for _, other in otherRadars do
        -- determine if we're too close to higher tech radars
        local range = other.Blueprint.Intel.RadarRadius
        if range then
            local squared = 0.64 * (range * range)
            local ox, _, oz = other:GetPositionXYZ()
            local dx = ox - basePos[1]
            local dz = oz - basePos[3]
            if dx * dx + dz * dz < squared then
                return false
            end
        end
    end
    return true
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
function CanBuildOnHydroLessThanDistance(aiBrain, locationType, distance, threatMin, threatMax, threatRings, threatType, maxNum)
    local engineerManager = aiBrain.BuilderManagers[locationType].EngineerManager
    if not engineerManager then
        return false
    end
    local position = engineerManager:GetLocationCoords()

    local markerTable = AIUtils.AIGetSortedHydroLocations(aiBrain, maxNum, threatMin, threatMax, threatRings, threatType, position)
    if markerTable[1] and VDist3(markerTable[1], position) < distance then
        return true
    end
    return false
end

--- Checks whether the builder / task is intentionally delayed
---@param aiBrain AIBrain
---@param PlatoonName string
---@return boolean
function CheckBuildPlattonDelay(aiBrain, PlatoonName)
    local timeToDelay = aiBrain.DelayEqualBuildPlattons[PlatoonName]
    if timeToDelay and timeToDelay > GetGameTimeSeconds() then
        return false
    end
    return true
end

function HaveUnitsInCategoryBeingUpgraded(aiBrain, numunits, category, compareType)
    -- get all units matching 'category'
    local unitsBuilding = aiBrain:GetListOfUnits(category, false)
    local numBuilding = 0
    -- own armyIndex
    local armyIndex = aiBrain:GetArmyIndex()
    -- loop over all units and search for upgrading units
    for _, unit in unitsBuilding do
        if not unit.Dead and not unit:BeenDestroyed() and unit:IsUnitState('Upgrading') and unit:GetAIBrain():GetArmyIndex() == armyIndex then
            numBuilding = numBuilding + 1
        end
    end
    --RNGLOG(aiBrain:GetArmyIndex()..' HaveUnitsInCategoryBeingUpgrade ( '..numBuilding..' '..compareType..' '..numunits..' ) --  return '..repr(CompareBody(numBuilding, numunits, compareType))..' ')
    return CompareBody(numBuilding, numunits, compareType)
end
function HaveLessThanUnitsInCategoryBeingUpgraded(aiBrain, numunits, category)
    return HaveUnitsInCategoryBeingUpgraded(aiBrain, numunits, category, '<')
end
function HaveGreaterThanUnitsInCategoryBeingUpgraded(aiBrain, numunits, category)
    return HaveUnitsInCategoryBeingUpgraded(aiBrain, numunits, category, '>')
end

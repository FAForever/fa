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
local AIUtils = import('/lua/ai/aiutilities.lua')
local ScenarioFramework = import('/lua/scenarioframework.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local Utils = import('/lua/utilities.lua')

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- function: HaveEqualToUnitsWithCategory = BuildCondition	doc = "Please work function docs."
--
-- parameter 0: string	aiBrain		= "default_brain"
-- parameter 1: int      numReq     	= 0					doc = "docs for param1"
-- parameter 2: expr   category        = categories.ALLUNITS			doc = "param2 docs"
-- parameter 3: bool   idleReq       = false         doc = "docs for param3"
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- function: HaveGreaterThanUnitsWithCategory = BuildCondition	doc = "Please work function docs."
--
-- parameter 0: string   aiBrain		    = "default_brain"
-- parameter 1: int      numReq     = 0					doc = "docs for param1"
-- parameter 2: expr   category        = categories.ALLUNITS		doc = "param2 docs"
-- parameter 3: expr   idleReq       = false         doc = "docs for param3"
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- function: HaveLessThanUnitsWithCategory = BuildCondition	doc = "Please work function docs."
--
-- parameter 0: string	aiBrain		= "default_brain"
-- parameter 1: int	numReq          = 0				doc = "docs for param1"
-- parameter 2: expr   category        = categories.ALLUNITS		doc = "param2 docs"
-- parameter 3: expr   idleReq       = false         doc = "docs for param3"
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- function: HaveLessThanUnitsWithCategoryInArea = BuildCondition	doc = "Please work function docs."
--
-- parameter 0: string	aiBrain	        = "default_brain"
-- parameter 1: int      numReq          = 0				doc = "docs for param1"
-- parameter 2: expr   category        = categories.ALLUNITS		doc = "param2 docs"
-- parameter 3: string   area            = "Area_1"
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function HaveLessThanUnitsWithCategoryInArea(aiBrain, numReq, category, area)
    local numUnits = ScenarioFramework.NumCatUnitsInArea(category, ScenarioUtils.AreaToRect(area), aiBrain)
    if numUnits < numReq then
        return true
    end
    return false
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- function: NumUnitsLessNearBase = BuildCondition	doc = "Please work function docs."
--
-- parameter 0: string	aiBrain         = "default_brain"
-- parameter 1: string	baseName        = "MAIN"			doc = "docs for param1"
-- parameter 2: expr   category        = categories.ALLUNITS
-- parameter 3: int      num             = 1
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function NumUnitsLessNearBase(aiBrain, baseName, category, num)
    if brain.BaseTemplates[baseName].Location == nil then
        return false
    else
        local unitList = brain:GetUnitsAroundPoint(category,
                                                   brain.BaseTemplates[baseName].Location,
                                                   brain.BaseTemplates[baseName].Radius, 'Ally')
        local count = 0
        for i,unit in unitList do
            if unit:GetAIBrain() == brain then
                count = count + 1
            end
        end
        if count < num then
            return true
        end
        return false
    end
end


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- function: HaveLessThanUnitComparison = BuildCondition	doc = "Check to see if the number of units in category 1 is less than the number of units in category 2"
--
-- parameter 0: string	aiBrain		= "default_brain"
-- parameter 1: expr	category1    = categories.ALLUNITS       doc = "Category of units to compare"
-- parameter 2: expr     category2    = categories.ALLUNITS       doc = "Category of units to compare against"
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- function: HaveGreaterThanUnitComparison = BuildCondition	doc = "Check to see if the number of units in category 1 is greater than the number of units in category 2"
--
-- parameter 0: string	aiBrain		= "default_brain"
-- parameter 1: expr	category1    = categories.ALLUNITS       doc = "Category of units to compare"
-- parameter 2: expr     category2    = categories.ALLUNITS       doc = "Category of units to compare against"
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- function: HaveLessThanVarTableUnitsWithCategory = BuildCondition	doc = "Please work function docs."
--
-- parameter 0: string	aiBrain		= "default_brain"
-- parameter 1: string	varName     = "VarName"     			doc = "VarTable Name"
-- parameter 2: expr     category    = categories.ALLUNITS		doc = "param2 docs"
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- function: HaveGreaterThanVarTableUnitsWithCategory = BuildCondition	doc = "Please work function docs."
--
-- parameter 0: string	aiBrain		= "default_brain"
-- parameter 1: string	varName     = "VarName"     			doc = "VarTable Name"
-- parameter 2: expr     category    = categories.ALLUNITS		doc = "param2 docs"
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- function: HaveLessThanVarTableUnitsWithCategoryInArea = BuildCondition	doc = "Please work function docs."
--
-- parameter 0: string	aiBrain		= "default_brain"
-- parameter 1: string	varName     = "VarName"     			doc = "VarTable Name"
-- parameter 2: expr     category    = categories.ALLUNITS		doc = "param2 docs"
-- parameter 3: string   area            = "Area_1"
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- function: HaveGreaterThanVarTableUnitsWithCategoryInArea = BuildCondition	doc = "Please work function docs."
--
-- parameter 0: string	aiBrain		= "default_brain"
-- parameter 1: string	varName     = "VarName"     			doc = "VarTable Name"
-- parameter 2: expr     category    = categories.ALLUNITS		doc = "param2 docs"
-- parameter 3: string   area            = "Area_1"
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- function: HaveGreaterThanUnitsInCategoryBeingBuilt = BuildCondition	doc = "Please work function docs."
--
-- parameter 0: string	aiBrain		= "default_brain"
-- parameter 1: int      numReq     	= 0					doc = "docs for param1"
-- parameter 2: expr   category        = categories.ALLUNITS			doc = "param2 docs"
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- function: HaveLessThanUnitsInCategoryBeingBuilt = BuildCondition	doc = "Please work function docs."
--
-- parameter 0: string	aiBrain		= "default_brain"
-- parameter 1: int      numReq     	= 0					doc = "docs for param1"
-- parameter 2: expr   category        = categories.ALLUNITS			doc = "param2 docs"
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- function: HaveLessThanUnitsAroundMarkerCategory = BuildCondition	doc = "Please work function docs."
--
-- parameter 0: string	aiBrain		= "default_brain"
-- parameter 1: string   markerType  = "Mass"
-- parameter 2: int      markerRadius = 50
-- parameter 3: string   locationType = "MAIN"
-- parameter 4: int      locationRadius = 50
-- parameter 5: int      unitCount    = 1
-- parameter 6: string   unitCategory = "ALLUNITS"
-- parameter 7: expr     threatMin = false
-- parameter 8: expr     threatMax = false
-- parameter 9: expr     threatRings = false
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function HaveLessThanUnitsAroundMarkerCategory(aiBrain, markerType, markerRadius, locationType, locationRadius,
    unitCount, unitCategory, threatMin, threatMax, threatRings, threatType)
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

function StartLocationNeedsEngineer(aiBrain, locationType, locationRadius, threatMin, threatMax, threatRings, threatType)
    local pos, name = AIUtils.AIFindStartLocationNeedsEngineer(aiBrain, locationType, locationRadius, threatMin, threatMax, threatRings, threatType)
    if pos then
        return true
    end
    return false
end

function StartLocationsFull(aiBrain, locationType, locationRadius, threatMin, threatMax, threatRings, threatType)
    local pos, name = AIUtils.AIFindStartLocationNeedsEngineer(aiBrain, locationType, locationRadius, threatMin, threatMax, threatRings, threatType)
    if not pos then
        return true
    end
    return false
end

function ExpansionAreaNeedsEngineer(aiBrain, locationType, locationRadius, threatMin, threatMax, threatRings, threatType)
    local pos, name = AIUtils.AIFindExpansionAreaNeedsEngineer(aiBrain, locationType, locationRadius, threatMin, threatMax, threatRings, threatType)
    if pos then
        return true
    end
    return false
end

function NavalAreaNeedsEngineer(aiBrain, locationType, locationRadius, threatMin, threatMax, threatRings, threatType)
    local pos, name = AIUtils.AIFindNavalAreaNeedsEngineer(aiBrain, locationType, locationRadius, threatMin, threatMax, threatRings, threatType)
    if pos then
        return true
    end
    return false
end

function NavalAreasFull(aiBrain, locationType, locationRadius, threatMin, threatMax, threatRings, threatType)
    local pos, name = AIUtils.AIFindNavalAreaNeedsEngineer(aiBrain, locationType, locationRadius, threatMin, threatMax, threatRings, threatType)
    if not pos then
        return true
    end
    return false
end

function DefensivePointNeedsStructure(aiBrain, locationType, locationRadius, category, markerRadius, unitMax, threatMin, threatMax, threatRings, threatType)
    local pos, name = AIUtils.AIFindDefensivePointNeedsStructure(aiBrain, locationType, locationRadius, category, markerRadius, unitMax, threatMin, threatMax, threatRings, threatType)
    if pos then
        return true
    end
    return false
end

function NavalDefensivePointNeedsStructure(aiBrain, locationType, locationRadius, category, markerRadius, unitMax, threatMin, threatMax, threatRings, threatType)
    local pos, name = AIUtils.AIFindNavalDefensivePointNeedsStructure(aiBrain, locationType, locationRadius, category, markerRadius, unitMax, threatMin, threatMax, threatRings, threatType)
    if pos then
        return true
    end
    return false
end

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



----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- function: HaveUnitsWithCategoryAndAlliance = BuildCondition	doc = "Please work function docs."
--
-- parameter 0: string   aiBrain		    = "default_brain"
-- parameter 1: bool   greater           = true          doc = "true = greater, false = less"
-- parameter 2: int    numReq     = 0					doc = "docs for param1"
-- parameter 3: expr   category        = categories.ALLUNITS		doc = "param2 docs"
-- parameter 4: expr   alliance       = false         doc = "docs for param3"
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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

function UnitsLessAtLocation(aiBrain, locationType, unitCount, unitCategory)
    return HaveUnitComparisonAtLocation(aiBrain, locationType, unitCount, unitCategory, '<')
end

function UnitsGreaterAtLocation(aiBrain, locationType, unitCount, unitCategory)
    return HaveUnitComparisonAtLocation(aiBrain, locationType, unitCount, unitCategory, '>')
end

-- ============================================ --
--     Builder Manager Location Pool Counts
-- ============================================ --
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

function PoolLessAtLocation(aiBrain, locationType, unitCount, unitCategory)
    return HavePoolUnitComparisonAtLocation(aiBrain, locationType, unitCount, unitCategory, '<')
end

function PoolGreaterAtLocation(aiBrain, locationType, unitCount, unitCategory)
    return HavePoolUnitComparisonAtLocation(aiBrain, locationType, unitCount, unitCategory, '>')
end

-- ======================================= --
--     Builder Manager Engineer Counts
-- ======================================= --
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

function EngineerLessAtLocation(aiBrain, locationType, unitCount, unitCategory)
    return EngineerComparisonAtLocation(aiBrain, locationType, unitCount, unitCategory, '<')
end

function EngineerGreaterAtLocation(aiBrain, locationType, unitCount, unitCategory)
    return EngineerComparisonAtLocation(aiBrain, locationType, unitCount, unitCategory, '>')
end

-- ====================================== --
--     Factory Manager Factory Counts
-- ====================================== --
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

function FactoryLessAtLocation(aiBrain, locationType, unitCount, unitCategory)
    return FactoryComparisonAtLocation(aiBrain, locationType, unitCount, unitCategory, '<')
end

function FactoryGreaterAtLocation(aiBrain, locationType, unitCount, unitCategory)
    return FactoryComparisonAtLocation(aiBrain, locationType, unitCount, unitCategory, '>')
end

-- ====================================== --
--     Factory Manager Factory Ratios
-- ====================================== --
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

function FactoryRatioLessAtLocation(aiBrain, locationType, unitCategory, unitCategory2)
    return FactoryRatioComparisonAtLocation(aiBrain, locationType, unitCategory, unitCategory2, '<')
end

function FactoryRatioGreaterAtLocation(aiBrain, locationType, unitCategory, unitCategory2)
    return FactoryRatioComparisonAtLocation(aiBrain, locationType, unitCategory, unitCategory2, '>')
end

-- ============================== --
--     Manager Builing Counts
-- ============================== --
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

function BuildingLessAtLocation(aiBrain, locationType, unitCount, unitCategory, builderCat)
    return LocationBuildingComparison(aiBrain, locationType, unitCount, unitCategory, '<', builderCat)
end

function BuildingGreaterAtLocation(aiBrain, locationType, unitCount, unitCategory, builderCat)
    return LocationBuildingComparison(aiBrain, locationType, unitCount, unitCategory, '>', builderCat)
end

-- ============================================ --
--     Factory Manager Building Unit Counts
-- ============================================ --
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

function LocationFactoriesBuildingLess(aiBrain, locationType, unitCount, unitCategory, facCat)
    return LocationFactoriesBuildingComparison(aiBrain, locationType, unitCount, unitCategory, '<', facCat)
end

function LocationFactoriesBuildingGreater(aiBrain, locationType, unitCount, unitCategory, facCat)
    return LocationFactoriesBuildingComparison(aiBrain, locationType, unitCount, unitCategory, '>', facCat)
end

-- ============================================= --
--     Engineer Manager Building Unit Counts
-- ============================================= --
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

function LocationEngineersBuildingLess(aiBrain, locationType, unitCount, unitCategory, engCat)
    return LocationEngineersBuildingComparison(aiBrain, locationType, unitCount, unitCategory, '<', engCat)
end

function LocationEngineersBuildingGreater(aiBrain, locationType, unitCount, unitCategory, engCat)
    return LocationEngineersBuildingComparison(aiBrain, locationType, unitCount, unitCategory, '>', engCat)
end

-- ===================================================== --
--     Engineers Wanting Assistance Build Conditions
-- ===================================================== --
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

function LocationEngineersBuildingAssistanceLess(aiBrain, locationType, unitCount, unitCategory, engCat)
    return LocationEngineersBuildingAssistanceComparison(aiBrain, locationType, unitCategory, '<', engCat)
end

function LocationEngineersBuildingAssistanceGreater(aiBrain, locationType, unitCount, unitCategory, engCat)
    return LocationEngineersBuildingAssistanceComparison(aiBrain, locationType, unitCategory, '>', engCat)
end

-- ==================================================== --
--     Factory Manager Check Maximum Factory Number
-- ==================================================== --
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
            local targetSize = v.Blueprint.Physics
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
function UnitCapCheckGreater(aiBrain, percent)
    local currentCount = GetArmyUnitCostTotal(aiBrain:GetArmyIndex())
    local cap = GetArmyUnitCap(aiBrain:GetArmyIndex())
    if (currentCount / cap) > percent then
        return true
    end
    return false
end

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
function CheckUnitRange(aiBrain, locationType, unitType, category, factionIndex)

    -- Find the unit's blueprint
    local template = import('/lua/BuildingTemplates.lua').BuildingTemplates[factionIndex or aiBrain:GetFactionIndex()]
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

function UnitsGreaterThanExpansionValue(aiBrain, unitCategory, large, small, naval)
    return UnitToExpansionsValue(aiBrain, unitCategory, '>=', large, small, naval)
end

function ExpansionBaseCheck(aiBrain)
    -- Removed automatic setting of Land-Expasions-allowed. We have a Game-Option for this.
    local checkNum = tonumber(ScenarioInfo.Options.LandExpansionsAllowed) or 3
    return ExpansionBaseCount(aiBrain, '<', checkNum)
end

function NavalBaseCheck(aiBrain)
    -- Removed automatic setting of naval-Expasions-allowed. We have a Game-Option for this.
    local checkNum = tonumber(ScenarioInfo.Options.NavalExpansionsAllowed) or 2
    return NavalBaseCount(aiBrain, '<', checkNum)
end

--DUNCAN - added to limit expansion bases.
function ExpansionBaseCount(aiBrain, compareType, checkNum)
       local expBaseCount = aiBrain:GetManagerCount('Start Location')
       expBaseCount = expBaseCount + aiBrain:GetManagerCount('Expansion Area')
       --LOG('*AI DEBUG: Expansion base count is ' .. expBaseCount .. ' checkNum is ' .. checkNum)
       if expBaseCount > checkNum + 1 then
            --LOG('*AI DEBUG: Expansion base count is ' .. expBaseCount .. ' checkNum is ' .. checkNum)
       end
       return CompareBody(expBaseCount, checkNum, compareType)
end

--DUNCAN - added to limit naval bases.
function NavalBaseCount(aiBrain, compareType, checkNum)
       local expBaseCount = aiBrain:GetManagerCount('Naval Area')
       --LOG('*AI DEBUG: Naval base count is ' .. expBaseCount .. ' checkNum is ' .. checkNum)
       return CompareBody(expBaseCount, checkNum, compareType)
end

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

--DUNCAN - credit to Sorian.
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

--DUNCAN - moved here from Markerbuildconditions so its evaluated instantly.
function CanBuildFirebase(aiBrain, locationType, radius, markerType, tMin, tMax, tRings, tType, maxUnits, unitCat, markerRadius)
    local ref, refName = AIUtils.AIFindFirebaseLocation(aiBrain, locationType, radius, markerType, tMin, tMax, tRings, tType, maxUnits, unitCat, markerRadius)
    if not ref then
        return false
    end
    return true
end

--DUNCAN - added for guard unit AI
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

--DUNCAN - credit to sorian
function T4BuildingCheck(aiBrain)
    if aiBrain.T4Building then
        return false
    end
    return true
end

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

function UnfinishedUnits(aiBrain, locationType, category)
    local engineerManager = aiBrain.BuilderManagers[locationType].EngineerManager
    if not engineerManager then
        return false
    end
    local unfinished = aiBrain:GetUnitsAroundPoint(category, engineerManager:GetLocationCoords(), engineerManager.Radius, 'Ally')
    for num, unit in unfinished do
        donePercent = unit:GetFractionComplete()
        if donePercent < 1 and GetGuards(aiBrain, unit) < 1 then
            return true
        end
    end
    return false
end

function GetGuards(aiBrain, Unit)
    local engs = aiBrain:GetUnitsAroundPoint(categories.ENGINEER, Unit:GetPosition(), 10, 'Ally')
    local count = 0
    local UpgradesFrom = Unit.Blueprint.General.UpgradesFrom
    for k,v in engs do
        if v.UnitBeingBuilt == Unit then
            count = count + 1
        end
    end
    if UpgradesFrom and UpgradesFrom ~= 'none' then -- Used to filter out upgrading units
        local oldCat = ParseEntityCategory(UpgradesFrom)
        local oldUnit = aiBrain:GetUnitsAroundPoint(oldCat, Unit:GetPosition(), 0, 'Ally')
        if oldUnit then
            count = count + 1
        end
    end
    return count
end

-- Buildcondition to check if a platoon is still delayed
function CheckBuildPlattonDelay(aiBrain, PlatoonName)
    if aiBrain.DelayEqualBuildPlattons[PlatoonName] and aiBrain.DelayEqualBuildPlattons[PlatoonName] > GetGameTimeSeconds() then
        return false
    end
    return true
end


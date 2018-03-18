local AIUtils = import('/lua/ai/aiutilities.lua')

function ReturnTrue(aiBrain)
    LOG('** true')
    return true
end

function ReturnFalse(aiBrain)
    LOG('** false')
    return false
end

--            { UBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 1, categories.RADAR * categories.TECH1 }},
function HaveUnitsInCategoryBeingUpgrade(aiBrain, numunits, category, compareType, DEBUG)
    -- convert text categories like 'MOBILE AIR' to 'categories.MOBILE * categories.AIR'
    if type(category) == 'string' then
        category = ParseEntityCategory(category)
    end
    -- get all units matching 'category'
    local unitsBuilding = aiBrain:GetListOfUnits(category, false)
    local numBuilding = 0
    -- own armyIndex
    local armyIndex = aiBrain:GetArmyIndex()
    -- loop over all units and search for upgrading units
    for unitNum, unit in unitsBuilding do
        if not unit.Dead and not unit:BeenDestroyed() and unit:IsUnitState('Upgrading') and unit:GetAIBrain():GetArmyIndex() == armyIndex then
            numBuilding = numBuilding + 1
        end
    end
    if DEBUG then
        LOG(aiBrain:GetArmyIndex()..' HaveUnitsInCategoryBeingUpgrade ( '..numBuilding..' '..compareType..' '..numunits..' ) --  return '..repr(CompareBody(numBuilding, numunits, compareType))..' ')
    end
    return CompareBody(numBuilding, numunits, compareType)
end
function HaveLessThanUnitsInCategoryBeingUpgrade(aiBrain, numunits, category, DEBUG)
    return HaveUnitsInCategoryBeingUpgrade(aiBrain, numunits, category, '<')
end
function HaveGreaterThanUnitsInCategoryBeingUpgrade(aiBrain, numunits, category, DEBUG)
    return HaveUnitsInCategoryBeingUpgrade(aiBrain, numunits, category, '>')
end

--            { UBC, 'CheckBuildPlattonDelay', { 'Factories' }},
--                DelayEqualBuildPlattons = {'Factories', 1},
function CheckBuildPlattonDelay(aiBrain, PlatoonName, DEBUG)
    if aiBrain.DelayEqualBuildPlattons[PlatoonName] and aiBrain.DelayEqualBuildPlattons[PlatoonName] > GetGameTimeSeconds() then
        if DEBUG then
            LOG('Builder, ['..PlatoonName..'] delayed.')
        end
        return false
    end
    return true
end

-- function GreaterThanGameTime(aiBrain, num) is multiplying the time by 0.5, if we have an cheat AI. But i need the real time here.
--            { UBC, 'GreaterThanGameTimeSeconds', { 180 } },
function GreaterThanGameTimeSeconds(aiBrain, num)
    if num < GetGameTimeSeconds() then
        return true
    end
    return false
end
--            { UBC, 'LessThanGameTimeSeconds', { 180 } },
function LessThanGameTimeSeconds(aiBrain, num)
    if num > GetGameTimeSeconds() then
        return true
    end
    return false
end

--            { UBC, 'BrainLowEnergyMode', {} },
function BrainLowEnergyMode(aiBrain)
    if not aiBrain.LowEnergyMode then
        return false
    end
    return true
end

--            { UBC, 'LessThanMassTrend', { 50.0 } },
function LessThanMassTrend(aiBrain, mTrend)
    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    if econ.MassTrend < mTrend then
        return true
    else
        return false
    end
end

--            { UBC, 'LessThanEnergyTrend', { 50.0 } },
function LessThanEnergyTrend(aiBrain, eTrend)
    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    if econ.EnergyTrend < eTrend then
        return true
    else
        return false
    end
end

--            { UBC, 'LessThanEconStorageCurrent', { 20000, 1000000 } },
function LessThanEconStorageCurrent(aiBrain, mStorage, eStorage)
    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    if (econ.MassStorage <= mStorage and econ.EnergyStorage <= eStorage) then
        return true
    end
    return false
end

--            { UBC, 'EnergyToMassRatioIncome', { 10.0, '>=',true } },  -- True if we have 10 times more Energy then Mass income ( 100 >= 10 = true )
function EnergyToMassRatioIncome(aiBrain, ratio, compareType, DEBUG)
    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    if DEBUG then
        LOG(aiBrain:GetArmyIndex()..' CompareBody {World} ( E:'..(econ.EnergyIncome*10)..' '..compareType..' M:'..(econ.MassIncome*10)..' ) -- R['..ratio..'] -- return '..repr(CompareBody(econ.EnergyIncome / econ.MassIncome, ratio, compareType)))
    end
    return CompareBody(econ.EnergyIncome / econ.MassIncome, ratio, compareType)
end
--            { UBC, 'HaveUnitRatioVersusCap', { 0.024, '<=', categories.STRUCTURE * categories.FACTORY * categories.LAND } }, -- Maximal 3 factories at 125 unitcap, 12 factories at 500 unitcap...
function HaveUnitRatioVersusCap(aiBrain, ratio, compareType, categoryOwn, DEBUG)
    local testCatOwn = categoryOwn
    if type(testCatOwn) == 'string' then
        testCatOwn = ParseEntityCategory(testCatOwn)
    end
    local numOwnUnits = aiBrain:GetCurrentUnits(testCatOwn)
    local cap = GetArmyUnitCap(aiBrain:GetArmyIndex())
    if DEBUG then
        LOG(aiBrain:GetArmyIndex()..' CompareBody {World} ( '..numOwnUnits..' '..compareType..' '..cap..' ) -- ['..ratio..'] -- '..repr(DEBUG)..' '..compareType..' '..cap..' return '..repr(CompareBody(numOwnUnits / cap, ratio, compareType)))
    end
    return CompareBody(numOwnUnits / cap, ratio, compareType)
end

function HaveUnitRatioVersusEnemy(aiBrain, ratio, categoryOwn, compareType, categoryEnemy, DEBUG)
    local testCatOwn = categoryOwn
    if type(testCatOwn) == 'string' then
        testCatOwn = ParseEntityCategory(testCatOwn)
    end
    local numOwnUnits = aiBrain:GetCurrentUnits(testCatOwn)
    local testCatEnemy = categoryEnemy
    if type(testCatEnemy) == 'string' then
        testCatEnemy = ParseEntityCategory(testCatEnemy)
    end
    local mapSizeX, mapSizeZ = GetMapSize()
    local numEnemyUnits = aiBrain:GetNumUnitsAroundPoint(testCatEnemy, Vector(mapSizeX/2,0,mapSizeZ/2), mapSizeX+mapSizeZ , 'Enemy')
    if DEBUG then
        LOG(aiBrain:GetArmyIndex()..' CompareBody {World} ( '..numOwnUnits..' '..compareType..' '..numEnemyUnits..' ) -- ['..ratio..'] -- '..categoryOwn..' '..compareType..' '..categoryEnemy..' return '..repr(CompareBody(numOwnUnits / numEnemyUnits, ratio, compareType)))
    end
    return CompareBody(numOwnUnits / numEnemyUnits, ratio, compareType)
end

function HaveUnitRatioAtLocation(aiBrain, locType, ratio, categoryNeed, compareType, categoryHave, DEBUG)
    local baseposition, radius
    if aiBrain:PBMHasPlatoonList() then
        for k,v in aiBrain.PBM.Locations do
            if v.LocationType == locType then
                baseposition = v.Location
                radius = v.Radius
                break
            end
        end
    elseif aiBrain.BuilderManagers[locType] then
        baseposition = aiBrain.BuilderManagers[locType].FactoryManager:GetLocationCoords()
        radius = aiBrain.BuilderManagers[locType].FactoryManager:GetLocationRadius()
    end
    if not baseposition then
        return false
    end
    local testCatNeed = categoryNeed
    if type(testCatNeed) == 'string' then
        testCatNeed = ParseEntityCategory(testCatNeed)
    end
    local numNeedUnits = aiBrain:GetNumUnitsAroundPoint(testCatNeed, baseposition, radius , 'Ally')
    
    local testCatHave = categoryHave
    if type(testCatHave) == 'string' then
        testCatHave = ParseEntityCategory(testCatHave)
    end
    local numHaveUnits = aiBrain:GetNumUnitsAroundPoint(testCatHave, baseposition, radius , 'Ally')
    if DEBUG then
        LOG(aiBrain:GetArmyIndex()..' CompareBody {'..locType..'} ( '..numNeedUnits..' '..compareType..' '..numHaveUnits..' ) -- ['..ratio..'] -- '..categoryNeed..' '..compareType..' '..categoryHave..' return '..repr(CompareBody(numNeedUnits / numHaveUnits, ratio, compareType)))
    end
    return CompareBody(numNeedUnits / numHaveUnits, ratio, compareType)
end

--{ UBC, 'HaveUnitRatioAtLocationRadiusVersusEnemy', { 1.50, 'LocationType', 90, 'STRUCTURE DEFENSE ANTIMISSILE TECH3', '<','SILO NUKE TECH3' } },
function HaveUnitRatioAtLocationRadiusVersusEnemy(aiBrain, ratio, locType, radius, categoryOwn, compareType, categoryEnemy, DEBUG)
    local baseposition
    if aiBrain:PBMHasPlatoonList() then
        for k,v in aiBrain.PBM.Locations do
            if v.LocationType == locType then
                baseposition = v.Location
                break
            end
        end
    elseif aiBrain.BuilderManagers[locType] then
        baseposition = aiBrain.BuilderManagers[locType].FactoryManager:GetLocationCoords()
    end
    if not baseposition then
        return false
    end
    local testCatOwn = categoryOwn
    if type(testCatOwn) == 'string' then
        testCatOwn = ParseEntityCategory(testCatOwn)
    end
    local numNeedUnits = aiBrain:GetNumUnitsAroundPoint(testCatOwn, baseposition, radius , 'Ally')

    local testCatEnemy = categoryEnemy
    if type(testCatEnemy) == 'string' then
        testCatEnemy = ParseEntityCategory(testCatEnemy)
    end
    local mapSizeX, mapSizeZ = GetMapSize()
    local numEnemyUnits = aiBrain:GetNumUnitsAroundPoint(testCatEnemy, Vector(mapSizeX/2,0,mapSizeZ/2), mapSizeX+mapSizeZ , 'Enemy')

    return CompareBody(numNeedUnits / numEnemyUnits, ratio, compareType)
end

--            { UBC, 'HaveGreaterThanArmyPoolWithCategory', { 0, categories.MASSEXTRACTION} },
function HavePoolUnitInArmy(aiBrain, unitCount, unitCategory, compareType)
    local testCat = unitCategory
    if type(unitCategory) == 'string' then
        testCat = ParseEntityCategory(unitCategory)
    end
    local poolPlatoon = aiBrain:GetPlatoonUniquelyNamed('ArmyPool')
    local numUnits = poolPlatoon:GetNumCategoryUnits(testCat)
    --LOG('* HavePoolUnitInArmy: numUnits= '..numUnits) 
    return CompareBody(numUnits, unitCount, compareType)
end
function HaveLessThanArmyPoolWithCategory(aiBrain, unitCount, unitCategory)
    return HavePoolUnitInArmy(aiBrain, unitCount, unitCategory, '<')
end
function HaveGreaterThanArmyPoolWithCategory(aiBrain, unitCount, unitCategory)
    return HavePoolUnitInArmy(aiBrain, unitCount, unitCategory, '>')
end

function ReclaimableMassInArea(aiBrain, locType)
    local ents = AIUtils.AIGetReclaimablesAroundLocation(aiBrain, locType)
    if ents and table.getn(ents) > 0 then
        for _, p in ents do
            if p.MaxMassReclaim and p.MaxMassReclaim > 1 then
                return true
            end
        end
    end
    return false
end

function ReclaimableEnergyInArea(aiBrain, locType)
    local ents = AIUtils.AIGetReclaimablesAroundLocation(aiBrain, locType)
    if ents and table.getn(ents) > 0 then
        for _, p in ents do
            if p.MaxEnergyReclaim and p.MaxEnergyReclaim > 1 then
                return true
            end
        end
    end
    return false
end

function CanBuildOnMassLessThanLocationDistance(aiBrain, locationType, distance, threatMin, threatMax, threatRings, threatType, maxNum )
    local locationPos = aiBrain.BuilderManagers[locationType].EngineerManager:GetLocationCoords()
    local engineerManager = aiBrain.BuilderManagers[locationType].EngineerManager
    if not engineerManager then
        WARN('*AI WARNING: Invalid location - ' .. locationType)
        return false
    end
    local markerTable = AIUtils.AIGetSortedMassLocations(aiBrain, maxNum, threatMin, threatMax, threatRings, threatType, locationPos)
    if markerTable[1] and VDist3( markerTable[1], locationPos ) < distance then
        --LOG('We can build in less than '..VDist3( markerTable[1], locationPos ))
        return true
    else
        --LOG('Outside range: '..VDist3( markerTable[1], locationPos ))
    end
    return false
end
function CanNotBuildOnMassLessThanLocationDistance(aiBrain, locationType, distance, threatMin, threatMax, threatRings, threatType, maxNum )
    local locationPos = aiBrain.BuilderManagers[locationType].EngineerManager:GetLocationCoords()
    local engineerManager = aiBrain.BuilderManagers[locationType].EngineerManager
    if not engineerManager then
        WARN('*AI WARNING: Invalid location - ' .. locationType)
        return false
    end
    local markerTable = AIUtils.AIGetSortedMassLocations(aiBrain, maxNum, threatMin, threatMax, threatRings, threatType, locationPos)
    if markerTable[1] and VDist3( markerTable[1], locationPos ) < distance then
        return false
    end
    return true
end

function HaveEnemyUnitAtLocation(aiBrain, radius, locationType, unitCount, categoryEnemy, compareType, DEBUG)
    local engineerManager = aiBrain.BuilderManagers[locationType].EngineerManager
    local categoryEnemy = categoryEnemy
    if type(categoryEnemy) == 'string' then
        categoryEnemy = ParseEntityCategory(categoryEnemy)
    end
    if not engineerManager then
        WARN('*AI WARNING: HaveEnemyUnitAtLocation - Invalid location - ' .. locationType)
        return false
    end

    local numUnits = 0
    local UnitPos = 0
    local dist = 0
    local basePosition = aiBrain.BuilderManagers[locationType].Position
    local numEnemyUnits = aiBrain:GetNumUnitsAroundPoint(categoryEnemy, basePosition, radius , 'Enemy')
    --DrawCircle(basePosition, radius, '0000FF')
    --DrawCircle(basePosition, radius+1, '0000FF')

    if DEBUG then
        LOG(aiBrain:GetArmyIndex()..' CompareBody {World} radius:['..radius..'] '..repr(DEBUG)..' ['..numEnemyUnits..'] '..compareType..' ['..unitCount..'] return '..repr(CompareBody(numEnemyUnits, unitCount, compareType)))
    end
    return CompareBody(numEnemyUnits, unitCount, compareType)
end
--            { UBC, 'EnemyUnitsGreaterAtLocationRadius', {  BasePanicZone, 'LocationType', 0, categories.MOBILE * categories.LAND }}, -- radius, LocationType, unitCount, categoryEnemy
function EnemyUnitsGreaterAtLocationRadius(aiBrain, radius, locationType, unitCount, categoryEnemy, DEBUG)
    return HaveEnemyUnitAtLocation(aiBrain, radius, locationType, unitCount, categoryEnemy, '>', DEBUG)
end
--            { UBC, 'EnemyUnitsLessAtLocationRadius', {  BasePanicZone, 'LocationType', 1, categories.MOBILE * categories.LAND }}, -- radius, LocationType, unitCount, categoryEnemy
function EnemyUnitsLessAtLocationRadius(aiBrain, radius, locationType, unitCount, categoryEnemy, DEBUG)
    return HaveEnemyUnitAtLocation(aiBrain, radius, locationType, unitCount, categoryEnemy, '<', DEBUG)
end


function GetEnemyUnits(aiBrain, unitCount, categoryEnemy, compareType, DEBUG)
    local testCatEnemy = categoryEnemy
    if type(testCatEnemy) == 'string' then
        testCatEnemy = ParseEntityCategory(testCatEnemy)
    end
    local mapSizeX, mapSizeZ = GetMapSize()
    local numEnemyUnits = aiBrain:GetNumUnitsAroundPoint(testCatEnemy, Vector(mapSizeX/2,0,mapSizeZ/2), mapSizeX+mapSizeZ , 'Enemy')
    if DEBUG then
        LOG(aiBrain:GetArmyIndex()..' CompareBody {World} '..categoryEnemy..' ['..numEnemyUnits..'] '..compareType..' ['..unitCount..'] return '..repr(CompareBody(numEnemyUnits, unitCount, compareType)))
    end
    return CompareBody(numEnemyUnits, unitCount, compareType)
end
function UnitsLessAtEnemy(aiBrain, unitCount, categoryEnemy, DEBUG)
    return GetEnemyUnits(aiBrain, unitCount, categoryEnemy, '<', DEBUG)
end
function UnitsGreaterAtEnemy(aiBrain, unitCount, categoryEnemy, DEBUG)
    return GetEnemyUnits(aiBrain, unitCount, categoryEnemy, '>', DEBUG)
end

-- For debug
--             { UBC, 'HaveUnitRatio', { 0.75, 'MASSEXTRACTION TECH1', '<=','MASSEXTRACTION TECH2',true } },
function HaveUnitRatio(aiBrain, ratio, categoryOne, compareType, categoryTwo, DEBUG)
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
    if DEBUG then
        LOG(aiBrain:GetArmyIndex()..' CompareBody {World} ( '..numOne..' '..compareType..' '..numTwo..' ) -- ['..ratio..'] -- '..categoryOne..' '..compareType..' '..categoryTwo..' return '..repr(CompareBody(numOne / numTwo, ratio, compareType)))
    end

    return CompareBody(numOne / numTwo, ratio, compareType)
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

-- Print the first Array level with values. Good for things like 'self' etc.
function debug_PrintArray(Table)
    for Index, Array in Table do
        if type(Array) == 'thread' or type(Array) == 'userdata' then
            LOG('Index['..Index..'] is type('..type(Array)..'). I won\'t print that!')
        elseif type(Array) == 'table' then
            LOG('Index['..Index..'] is type('..type(Array)..'). I won\'t print that!')
        else
            LOG('Index['..Index..'] is type('..type(Array)..'). "', repr(Array),'".')
        end
    end
end
--    DrawCircle(engineerManager:GetLocationCoords(), radius, '0000FF')
--    DrawCircle(engineerManager:GetLocationCoords(), engineerManager:GetLocationRadius(), 'FF0000')





--            { UBC, 'EngineerManagerUnitsAtLocation', { 'MAIN', '<=', 100,  'ENGINEER TECH3' } },
function EngineerManagerUnitsAtLocation(aiBrain, LocationType, compareType, numUnits, category, DEBUG)
    local testCat = category
    if type(testCat) == 'string' then
        testCat = ParseEntityCategory(testCat)
    end
    local numEngineers = aiBrain.BuilderManagers[LocationType].EngineerManager:GetNumCategoryUnits('Engineers', testCat)
    if DEBUG then
        LOG('* EngineerManagerUnitsAtLocation: '..LocationType..' ( engineers: '..numEngineers..' '..compareType..' '..numUnits..' ) -- '..category..' return '..repr(CompareBody( numEngineers, numUnits, compareType )) )
    end
    return CompareBody( numEngineers, numUnits, compareType )
end

--            { UBC, 'BuildOnlyOnLocation', { 'LocationType', 'MAIN' } },
function BuildOnlyOnLocation(aiBrain, LocationType, AllowedLocationType)
    --LOG('* BuildOnlyOnLocation: we are on location '..LocationType..', Allowed locations are: '..AllowedLocationType..'')
    if string.find(LocationType, AllowedLocationType) then
        return true
    end
    return false
end
--            { UBC, 'BuildNotOnLocation', { 'LocationType', 'MAIN' } },
function BuildNotOnLocation(aiBrain, LocationType, ForbiddenLocationType, DEBUG)
    if string.find(LocationType, ForbiddenLocationType) then
        if DEBUG then
            LOG('* BuildOnlyOnLocation: we are on location '..LocationType..', forbidden locations are: '..ForbiddenLocationType..'. return false (don\'t build it)')
        end
        return false
    end
    if DEBUG then
        LOG('* BuildOnlyOnLocation: we are on location '..LocationType..', forbidden locations are: '..ForbiddenLocationType..'. return true (OK, build it)')
    end
    return true
end

-----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
-- In progess, next project, not working...
-----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
--          { UBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.OMNI * categories.STRUCTURE, 'RADAR STRUCTURE' } },
function HaveLessThanUnitsInCategoryBeingBuilt(aiBrain, numReq, category, constructionCat)
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
        #DUNCAN - added to pick up engineers that havent started building yet... does it work?
        if not unit:BeenDestroyed() and not unit:IsUnitState('Building') then
            local buildingUnit = unit.UnitBeingBuilt
            if buildingUnit and not buildingUnit.Dead and EntityCategoryContains(category, buildingUnit) then
                #LOG('Engi building but not in building state...')
                numBuilding = numBuilding + 1
            end
        end
    end
    
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
        numUnits = aiBrain:NumCurrentlyBuilding(cat, cat + categories.CONSTRUCTION + consCat )
    else
        numUnits = aiBrain:NumCurrentlyBuilding(cat, cat + categories.CONSTRUCTION)
    end
    if numUnits ~= numBuilding then
        LOG('HaveLessThanUnitsInCategoryBeingBuilt ERROR! ORIG [ '..numUnits..' ] Sorian [ '..numBuilding..' ] ')
    else
        --LOG('HaveLessThanUnitsInCategoryBeingBuilt OK '..numUnits..' ')
    end
    if numUnits < numReq then
        return true
    end
    return false
end

function HaveGreaterThanUnitsInCategoryBeingBuiltAtLocation(aiBrain, locationType, numReq, category, constructionCat)
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
        numUnits = table.getn( GetUnitsBeingBuiltLocation(aiBrain, locationType, cat, cat + categories.ENGINEER * categories.MOBILE + consCat) or {} )
    else
        numUnits = table.getn( GetUnitsBeingBuiltLocation(aiBrain,locationType, cat, cat + categories.ENGINEER * categories.MOBILE ) or {} )
    end
    if numUnits > numReq then
        return true
    end
    return false
end

function GetUnitsBeingBuiltLocation(aiBrain, locationType, buildingCategory, builderCategory)
    local LocationPosition, Radius
    if aiBrain.BuilderManagers[locationType] then
        LocationPosition = aiBrain.BuilderManagers[locationType].FactoryManager:GetLocationCoords()
        Radius = aiBrain.BuilderManagers[locationType].FactoryManager:GetLocationRadius()
    elseif aiBrain:PBMHasPlatoonList() then
        for k,v in aiBrain.PBM.Locations do
            if v.LocationType == locationType then
                LocationPosition = v.Location
                Radius = v.Radius
                break
            end
        end
    end
    if not LocationPosition then
        return false
    end
    local filterUnits = GetOwnUnitsAroundLocation(aiBrain, builderCategory, LocationPosition, Radius)
    local retUnits = {}
    for k,v in filterUnits do
        -- Only assist if allowed
        if v.DesiresAssist == false then
            continue
        end
        -- Engineer doesn't want any more assistance
        if v.NumAssistees and table.getn(v:GetGuards()) >= v.NumAssistees then
            continue
        end
        -- skip the unit, if it's not building or upgrading.
        if not v:IsUnitState('Building') and not v:IsUnitState('Upgrading') then
            continue
        end
        local beingBuiltUnit = v.UnitBeingBuilt
        if not beingBuiltUnit or not EntityCategoryContains(buildingCategory, beingBuiltUnit) then
            continue
        end
        table.insert(retUnits, v)
    end
    return retUnits
end

function GetOwnUnitsAroundLocation(aiBrain, category, location, radius)
    local units = aiBrain:GetUnitsAroundPoint(category, location, radius, 'Ally')
    local index = aiBrain:GetArmyIndex()
    local retUnits = {}
    for _, v in units do
        if not v.Dead and v:GetAIBrain():GetArmyIndex() == index then
            table.insert(retUnits, v)
        end
    end
    return retUnits
end

local timedilatation = false
function IsGameSimSpeedLow(aiBrain)
    local SystemTime = GetSystemTimeSecondsOnlyForProfileUse()
    local GameTime = GetGameTimeSeconds()
    if not timedilatation then
        timedilatation = GetSystemTimeSecondsOnlyForProfileUse() - GetGameTimeSeconds()
    end
        
    LOG('** SystemTime'..SystemTime)
    LOG('** timedilatation'..timedilatation)
    LOG('** SystemTimedilatation'..(GetSystemTimeSecondsOnlyForProfileUse()-timedilatation))
    LOG('** GameTime'..GameTime)
    
    
    LOG('** true')
    return true
end

function HaveLessThanIdleEngineers(aiBrain, count, tech)
    local ENGINEERs = aiBrain:GetListOfUnits(categories.ENGINEER, true, false)
    local engineers = {}
    engineers[5] = EntityCategoryFilterDown(categories.SUBCOMMANDER, ENGINEERs)
    engineers[4] = EntityCategoryFilterDown(categories.TECH3 - categories.SUBCOMMANDER, ENGINEERs)
    engineers[3] = EntityCategoryFilterDown(categories.FIELDENGINEER, ENGINEERs)
    engineers[2] = EntityCategoryFilterDown(categories.TECH2 - categories.FIELDENGINEER, ENGINEERs)
    engineers[1] = EntityCategoryFilterDown(categories.TECH1 - categories.COMMAND, ENGINEERs)
    local c = 0
    for _, v in engineers[tech] do
        if v:IsIdleState() then
            c=c+1
        end
    end
    --LOG('tech '..tech..' - Eng='..table.getn(engineers[tech])..' - idle='..c..' == '..repr(c < count))
    return c < count
end

function LessEnergyStorageMax(aiBrain, eStorage)
    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    if econ.EnergyMaxStored < eStorage then
        return true
    end
    return false
end
function LessMassStorageMax(aiBrain, mStorage)
    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    if econ.MassMaxStored < mStorage then
        return true
    end
    return false
end

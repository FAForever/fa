#****************************************************************************
#**
#**  File     :  /lua/SorianBuildConditions.lua
#**  Author(s): Michael Robbins aka Sorian
#**
#**  Summary  : Generic AI Platoon Build Conditions
#**             Build conditions always return true or false
#**
#****************************************************************************
local AIUtils = import('/lua/ai/aiutilities.lua')
local ScenarioFramework = import('/lua/scenarioframework.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local Utils = import('/lua/utilities.lua')
local SUtils = import('/lua/AI/sorianutilities.lua')
local MABC = import('/lua/editor/MarkerBuildConditions.lua')
local AIAttackUtils = import('/lua/AI/aiattackutilities.lua')

##############################################################################################################
# function: IsBadMap = BuildCondition
#
# parameter 0: string   aiBrain         = "default_brain"
# parameter 2: bool     bool            = true = is a bad map, false = is not a bad map
#
##############################################################################################################

function IsBadMap(aiBrain, bool)
    if not SUtils.CheckForMapMarkers(aiBrain) and bool then
        return true
    elseif SUtils.CheckForMapMarkers(aiBrain) and not bool then
        return true
    end
    return false
end

function CategoriesNotRestricted(aiBrain, resTable)
    local restrictions = ScenarioInfo.Options.RestrictedCategories
    if not restrictions then return false end
    for _, rescheck in resTable do
        for _, restriction in restrictions do
            if rescheck == restriction then
                return false
            end
        end
    end
    return true
end

##############################################################################################################
# function: IsWaterMap = BuildCondition
#
# parameter 0: string   aiBrain         = "default_brain"
# parameter 2: bool     bool            = true = is a water map, false = is not a water map
#
##############################################################################################################

function IsWaterMap(aiBrain, bool)
    local startX, startZ = aiBrain:GetArmyStartPos()
    local navalMarker = AIUtils.AIGetClosestMarkerLocation(aiBrain, 'Naval Area', startX, startZ)
    if navalMarker and bool then
        return true
    elseif not navalMarker and not bool then
        return true
    end
    return false
end

##############################################################################################################
# function: IsIslandMap = BuildCondition
#
# parameter 0: string   aiBrain         = "default_brain"
# parameter 2: bool     bool            = true = is a island map, false = is not a island map
#
##############################################################################################################

function IsIslandMap(aiBrain, bool)
    local startX, startZ = aiBrain:GetArmyStartPos()
    local enemyX, enemyZ
    if aiBrain:GetCurrentEnemy() then
        enemyX, enemyZ = aiBrain:GetCurrentEnemy():GetArmyStartPos()
    else
        enemyX, enemyZ = SUtils.GetRandomEnemyPos(aiBrain)
    end
    local navalMarker = AIUtils.AIGetClosestMarkerLocation(aiBrain, 'Island', startX, startZ)
    local path, reason = false
    if enemyX then
        path, reason = AIAttackUtils.PlatoonGenerateSafePathTo(aiBrain, 'Land', {startX,0,startZ}, {enemyX,0,enemyZ}, 10)
    end
    if (navalMarker and not path) and bool then
        return true
    elseif (not navalMarker or path) and not bool then
        return true
    end
    return false
end

##############################################################################################################
# function: AIType = BuildCondition
#
# parameter 0: string   aiBrain         = "default_brain"
# parameter 1: string   aitype          = "AI Personality"
# parameter 2: bool     bool            = true = aitype matches, false = aitype does not match
#
##############################################################################################################

function AIType(aiBrain, aitype, bool)
    local per = ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality
    if aitype == per and bool then
        return true
    elseif aitype != per and not bool then
        return true
    end
    return false
end

function MarkerLessThan(aiBrain, locationType, markerTypes, distance, checkForBad)
    if checkForBad and not SUtils.CheckForMapMarkers(aiBrain) then
        return true
    end
    local engineerManager = aiBrain.BuilderManagers[locationType].EngineerManager
    if not engineerManager then
        return false
    end
    local pos = engineerManager:GetLocationCoords()
    for k,v in markerTypes do
        local marker = AIUtils.AIGetClosestMarkerLocation(aiBrain, v, pos[1], pos[3])
        if marker and VDist2Sq(marker[1], marker[3], pos[1], pos[3]) < distance * distance then
            return true
        elseif not marker then
            return true
        end
    end
    return false
end

##############################################################################################################
# function: GreaterThanGameTime = BuildCondition  doc = "Please work function docs."
#
# parameter 0: string   aiBrain         = "default_brain"
# parameter 1: int  num             = 1         doc = "docs for param1"
#
##############################################################################################################
function GreaterThanGameTime(aiBrain, num)
    local time = GetGameTimeSeconds()
    local cheatmult = tonumber(ScenarioInfo.Options.CheatMult) or 2
    local buildmult = tonumber(ScenarioInfo.Options.BuildMult) or 2
    local cheatAdjustment = (cheatmult + buildmult) / 2
    if aiBrain.CheatEnabled and (num / cheatAdjustment) < time then
        return true
    elseif num < time then
        return true
    end
    return false
end

##############################################################################################################
# function: LessThanGameTime = BuildCondition  doc = "Please work function docs."
#
# parameter 0: string   aiBrain         = "default_brain"
# parameter 1: int  num             = 1         doc = "docs for param1"
#
##############################################################################################################
function LessThanGameTime(aiBrain, num)
    return (not GreaterThanGameTime(aiBrain, num))
end

##############################################################################################################
# function: EnemiesLessThan = BuildCondition
#
# parameter 0: string   aiBrain         = "default_brain"
# parameter 1: integer  num             = "Number of enemies"
#
##############################################################################################################
function EnemyToAllyRatioLessOrEqual(aiBrain, num)
    local enemies = 0
    local allies = 0
    for k,v in ArmyBrains do
        if not v.Result == "defeat" and not ArmyIsCivilian(v:GetArmyIndex()) and IsEnemy(v:GetArmyIndex(), aiBrain:GetArmyIndex()) then
            enemies = enemies + 1
        elseif not v.Result == "defeat" and not ArmyIsCivilian(v:GetArmyIndex()) and IsAlly(v:GetArmyIndex(), aiBrain:GetArmyIndex()) then
            allies = allies + 1
        end
    end
    if enemies / allies <= num then
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
    if aiBrain:GetThreatAtPosition(position, testRings, true, threatType or 'Overall') < threatValue then
        return true
    end
    return false
end

##############################################################################################################
# function: ReclaimablesInArea = BuildCondition   doc = "Please work function docs."
#
# parameter 0: string   aiBrain     = "default_brain"
# parameter 1: string   locType     = "MAIN"
#
##############################################################################################################
function ReclaimablesInArea(aiBrain, locType, threatValue, threatType, rings)
    if aiBrain:GetEconomyStoredRatio('MASS') > .5 and aiBrain:GetEconomyStoredRatio('ENERGY') > .5 then
        return false
    end

    local testRings = rings or 0

    local ents = AIUtils.AIGetReclaimablesAroundLocation(aiBrain, locType)
    if not ents or table.empty(ents) then
        return false
    end
    for k,v in ents do
        if not aiBrain.BadReclaimables[v] and aiBrain:GetThreatAtPosition(v:GetPosition(), testRings, true, threatType or 'Overall') <= threatValue then
            return true
        end
    end

    return false
end

##############################################################################################################
# function: ClosestEnemyLessThan = BuildCondition
#
# parameter 0: string   aiBrain         = "default_brain"
# parameter 1: integer  distance        = "distance"
#
##############################################################################################################
function ClosestEnemyLessThan(aiBrain, distance)
    local startX, startZ = aiBrain:GetArmyStartPos()
    local closest
    for k,v in ArmyBrains do
        if not v.Result == "defeat" and not ArmyIsCivilian(v:GetArmyIndex()) and IsEnemy(v:GetArmyIndex(), aiBrain:GetArmyIndex()) then
            local estartX, estartZ = v:GetArmyStartPos()
            local tempDistance = VDist2Sq(startX, startZ, estartX, estartZ)
            if not closest or tempDistance < closest then
                closest = tempDistance
            end
        end
        if closest and closest < distance * distance then
            return true
        end
    end
    return false
end

function DamagedStructuresInArea(aiBrain, locationtype)
    local engineerManager = aiBrain.BuilderManagers[locationtype].EngineerManager
    if not engineerManager then
        return false
    end
    local Structures = AIUtils.GetOwnUnitsAroundPoint(aiBrain, categories.STRUCTURE - (categories.TECH1 - categories.FACTORY), engineerManager:GetLocationCoords(), engineerManager.Radius)
    for k,v in Structures do
        if not v.Dead and v:GetHealthPercent() < .8 then
        #LOG('*AI DEBUG: DamagedStructuresInArea return true')
            return true
        end
    end
    #LOG('*AI DEBUG: DamagedStructuresInArea return false')
    return false
end

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
        if VDist2(startX, startZ, loc[1], loc[3]) < distance and aiBrain:CanBuildStructureAt('ueb1102', loc) then
            return true
        end
    end
    return false
end

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

function NoMarkerLessThanDistance(aiBrain, markerType, distance, threatMin, threatMax, threatRings, threatType, startX, startZ)
    return not MABC.MarkerLessThanDistance(aiBrain, markerType, distance, threatMin, threatMax, threatRings, threatType, startX, startZ)
end

##############################################################################################################
# function: MapGreaterThan = BuildCondition
#
# parameter 0: string   aiBrain         = "default_brain"
# parameter 1: integer  sizeX           = "sizeX"
# parameter 2: integer  sizeZ           = "sizeZ"
#
##############################################################################################################
function MapGreaterThan(aiBrain, sizeX, sizeZ)
    local mapSizeX, mapSizeZ = GetMapSize()
    if mapSizeX > sizeX or mapSizeZ > sizeZ then
        #LOG('*AI DEBUG: MapGreaterThan returned True SizeX: ' .. sizeX .. ' sizeZ: ' .. sizeZ)
        return true
    end
    #LOG('*AI DEBUG: MapGreaterThan returned False SizeX: ' .. sizeX .. ' sizeZ: ' .. sizeZ)
    return false
end

##############################################################################################################
# function: MapLessThan = BuildCondition
#
# parameter 0: string   aiBrain         = "default_brain"
# parameter 1: integer  sizeX           = "sizeX"
# parameter 2: integer  sizeZ           = "sizeZ"
#
##############################################################################################################
function MapLessThan(aiBrain, sizeX, sizeZ)
    local mapSizeX, mapSizeZ = GetMapSize()
    if mapSizeX < sizeX and mapSizeZ < sizeZ then
        #LOG('*AI DEBUG: MapLessThan returned True SizeX: ' .. sizeX .. ' sizeZ: ' .. sizeZ)
        return true
    end
    #LOG('*AI DEBUG: MapLessThan returned False SizeX: ' .. sizeX .. ' sizeZ: ' .. sizeZ)
    return false
end

##############################################################################################################
# function: PoolThreatGreaterThanEnemyBase = BuildCondition
#
# parameter 0: string   aiBrain        = "default_brain"
# parameter 1: string	  locationType   = "loactionType"
# parameter 2: string   ucat            = "Unit Category"
# parameter 3: string   ttype           = "Enemy Threat Type"
# parameter 4: string   uttype          = "Unit Threat Type"
# parameter 5: integer divideby        = "Divide Unit Threat by"
#
##############################################################################################################
function PoolThreatGreaterThanEnemyBase(aiBrain, locationType, ucat, ttype, uttype, divideby)
    local pool = aiBrain:GetPlatoonUniquelyNamed('ArmyPool')
    local engineerManager = aiBrain.BuilderManagers[locationType].EngineerManager
    local divby = divideby or 1
    if not engineerManager then
        return false
    end

    if aiBrain:GetCurrentEnemy() then
        enemy = aiBrain:GetCurrentEnemy()
        enemyIndex = aiBrain:GetCurrentEnemy():GetArmyIndex()
    else
        return false
    end
    local StartX, StartZ = enemy:GetArmyStartPos()
    local position = engineerManager:GetLocationCoords()
    local radius = engineerManager.Radius

    local enemyThreat = aiBrain:GetThreatAtPosition({StartX, 0, StartZ}, 1, true, ttype or 'Overall', enemyIndex)
    local Threat = pool:GetPlatoonThreat(uttype or 'Overall', ucat, position, radius)
    if SUtils.Round((Threat / divby), 1) > enemyThreat then
        return true
    end
    return false
end

##############################################################################################################
# function: LessThanThreatAtEnemyBase = BuildCondition
#
# parameter 0: string   aiBrain        = "default_brain"
# parameter 3: string   ttype          = "Enemy Threat Type"
# parameter 5: integer number         = "Threat Amount"
#
##############################################################################################################
function LessThanThreatAtEnemyBase(aiBrain, ttype, number)
    if aiBrain:GetCurrentEnemy() then
        enemy = aiBrain:GetCurrentEnemy()
        enemyIndex = aiBrain:GetCurrentEnemy():GetArmyIndex()
    else
        return false
    end

    local StartX, StartZ = enemy:GetArmyStartPos()

    local enemyThreat = aiBrain:GetThreatAtPosition({StartX, 0, StartZ}, 1, true, ttype or 'Overall', enemyIndex)
    if number < enemyThreat then
        return true
    end
    return false
end

function GreaterThanThreatAtEnemyBase(aiBrain, ttype, number)
    return not LessThanThreatAtEnemyBase(aiBrain, ttype, number)
end

##############################################################################################################
# function: GreaterThanEnemyUnitsAroundBase = BuildCondition
#
# parameter 0: string   aiBrain         = "default_brain"
# parameter 1: integer  numUnits        = "Number of Units"
# parameter 2: integer  radius          = "radius"
# parameter 3: integer  unitCat         = "Unit Category"
#
##############################################################################################################
function GreaterThanEnemyUnitsAroundBase(aiBrain, locationtype, numUnits, unitCat, radius)
    local engineerManager = aiBrain.BuilderManagers[locationtype].EngineerManager
    if not engineerManager then
        return false
    end
    if type(unitCat) == 'string' then
        unitCat = ParseEntityCategory(unitCat)
    end
    local Units = aiBrain:GetNumUnitsAroundPoint(unitCat, engineerManager:GetLocationCoords(), radius, 'Enemy')
    if Units > numUnits then
        return true
    end
    return false
end

##############################################################################################################
# function: UnfinishedUnits = BuildCondition
#
# parameter 0: string   aiBrain         = "default_brain"
# parameter 1: integer  radius          = "radius"
# parameter 2: string   category        = "Unit category"
#
##############################################################################################################
function UnfinishedUnits(aiBrain, locationType, category)
    local engineerManager = aiBrain.BuilderManagers[locationType].EngineerManager
    if not engineerManager then
        return false
    end
    local unfinished = aiBrain:GetUnitsAroundPoint(category, engineerManager:GetLocationCoords(), engineerManager.Radius, 'Ally')
    for num, unit in unfinished do
        donePercent = unit:GetFractionComplete()
        if donePercent < 1 and SUtils.GetGuards(aiBrain, unit) < 1 then
            return true
        end
    end
    return false
end

##############################################################################################################
# function: ShieldDamaged = BuildCondition
#
# parameter 0: string   aiBrain         = "default_brain"
# parameter 1: integer  radius          = "radius"
#
##############################################################################################################
function ShieldDamaged(aiBrain, locationType)
    local engineerManager = aiBrain.BuilderManagers[locationType].EngineerManager
    if not engineerManager then
        return false
    end
    local shields = aiBrain:GetUnitsAroundPoint(categories.STRUCTURE * categories.SHIELD, engineerManager:GetLocationCoords(), engineerManager.Radius, 'Ally')
    for num, unit in shields do
        if not unit.Dead and unit:ShieldIsOn() then
            shieldPercent = (unit.MyShield:GetHealth() / unit.MyShield:GetMaxHealth())
            if shieldPercent < 1 and SUtils.GetGuards(aiBrain, unit) < 3 then
                return true
            end
        end
    end
    return false
end

function NoRushTimeCheck(aiBrain, timeLeft)
    if ScenarioInfo.Options.NoRushOption and ScenarioInfo.Options.NoRushOption != 'Off' then
        if tonumber(ScenarioInfo.Options.NoRushOption) * 60 < GetGameTimeSeconds() + timeLeft then
            return true
        else
            return false
        end
    elseif ScenarioInfo.Options.NoRushOption and ScenarioInfo.Options.NoRushOption == 'Off' then
        return true
    end
    return true
end

function NoRush(aiBrain)
    if ScenarioInfo.Options.NoRushOption and ScenarioInfo.Options.NoRushOption != 'Off' then
        if tonumber(ScenarioInfo.Options.NoRushOption) * 60 > GetGameTimeSeconds() then
            return true
        else
            return false
        end
    elseif ScenarioInfo.Options.NoRushOption and ScenarioInfo.Options.NoRushOption == 'Off' then
        return false
    end
    return false
end

function HaveComparativeUnitsWithCategoryAndAlliance(aiBrain, greater, myCategory, eCategory, alliance)
    if type(eCategory) == 'string' then
        eCategory = ParseEntityCategory(eCategory)
    end
    if type(myCategory) == 'string' then
        myCategory = ParseEntityCategory(myCategory)
    end
    local myUnits = aiBrain:GetCurrentUnits(myCategory)
    local numUnits = aiBrain:GetNumUnitsAroundPoint(eCategory, Vector(0,0,0), 100000, alliance)
    if alliance == 'Ally' then
        numUnits = numUnits - aiBrain:GetCurrentUnits(myCategory)
    end
    if numUnits > myUnits and greater then
        return true
    elseif numUnits < myUnits and not greater then
        return true
    end
    return false
end

function HaveRatioUnitsWithCategoryAndAlliance(aiBrain, less, ratio, myCategory, eCategory, alliance)
    if type(eCategory) == 'string' then
        eCategory = ParseEntityCategory(eCategory)
    end
    if type(myCategory) == 'string' then
        myCategory = ParseEntityCategory(myCategory)
    end
    local myUnits = aiBrain:GetCurrentUnits(myCategory)
    local numUnits = aiBrain:GetNumUnitsAroundPoint(eCategory, Vector(0,0,0), 100000, alliance)
    if alliance == 'Ally' then
        numUnits = numUnits - aiBrain:GetCurrentUnits(myCategory)
    end
    if numUnits / myUnits <= ratio and less then
        return true
    elseif numUnits / myUnits >= ratio and not less then
        return true
    end
    return false
end

function HaveComparativeUnitsWithCategoryAndAllianceAtLocation(aiBrain, locationtype, greater, myCategory, eCategory, alliance)
    if type(eCategory) == 'string' then
        eCategory = ParseEntityCategory(eCategory)
    end
    if type(myCategory) == 'string' then
        myCategory = ParseEntityCategory(myCategory)
    end
    local engineerManager = aiBrain.BuilderManagers[locationtype].EngineerManager
    if not engineerManager then
        return false
    end
    local myUnits = table.getn(AIUtils.GetOwnUnitsAroundPoint(aiBrain, myCategory, engineerManager:GetLocationCoords(), engineerManager.Radius))
    local numUnits = aiBrain:GetNumUnitsAroundPoint(eCategory, Vector(0,0,0), 100000, alliance)
    if alliance == 'Ally' then
        numUnits = numUnits - aiBrain:GetCurrentUnits(myCategory)
    end
    if numUnits > myUnits and greater then
        return true
    elseif numUnits < myUnits and not greater then
        return true
    end
    return false
end

##############################################################################################################
# function: CmdrHasUpgrade = BuildCondition
#
# parameter 0: string   aiBrain         = "default_brain"
# parameter 1: string   upgrade         = "upgrade"
#
##############################################################################################################
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

function SCUNeedsUpgrade(aiBrain, upgrade)
    local units = aiBrain:GetListOfUnits(categories.SUBCOMMANDER, false)
    local needsUpgrade = false
    for k,v in units do
        if v:IsUnitState('Upgrading') then
            return false
        end
        if not v:HasEnhancement(upgrade) then
            needsUpgrade = true
        end
    end
    return needsUpgrade
end

function T4ThreatExists(aiBrain, t4types, t4cats)
    for k,v in t4types do
        if aiBrain.T4ThreatFound[v] then
            return true
        end
    end
    if type(t4cats) == 'string' then
        t4cats = ParseEntityCategory(t4cats)
    end
    if aiBrain:GetNumUnitsAroundPoint(categories.EXPERIMENTAL * t4cats, Vector(0,0,0), 100000, 'Enemy') > 0 then
        for k,v in t4types do
            aiBrain.T4ThreatFound[v] = true
        end
        aiBrain:ForkThread(aiBrain.T4ThreatMonitorTimeout, t4types)
        return true
    end
    return false
end

function CanBuildFirebase(aiBrain, locationType, radius, markerType, tMin, tMax, tRings, tType, maxUnits, unitCat, markerRadius)
    local ref, refName = AIUtils.AIFindFirebaseLocationSorian(aiBrain, locationType, radius, markerType, tMin, tMax, tRings, tType, maxUnits, unitCat, markerRadius)
    if not ref then
        return false
    end
    return true
end

function TargetHasLessThanUnitsWithCategory(aiBrain, numReq, category)
    local testCat = category
    local enemyBrain = aiBrain:GetCurrentEnemy()
    local count = 0
    if not enemyBrain then
        return false
    end
    local enemyIndex = enemyBrain:GetArmyIndex()
    if type(category) == 'string' then
        testCat = ParseEntityCategory(category)
    end
    local eUnits = aiBrain:GetUnitsAroundPoint(testCat, Vector(0,0,0), 100000, 'Enemy')
    for k,v in eUnits do
        if v:GetAIBrain():GetArmyIndex() == enemyIndex then
            count = count + 1
        end
        if count > numReq then
            return false
        end
    end
    return true
end

function TargetHasGreaterThanUnitsWithCategory(aiBrain, numReq, category)
    local testCat = category
    local enemyBrain = aiBrain:GetCurrentEnemy()
    local count = 0
    if not enemyBrain then
        return false
    end
    local enemyIndex = enemyBrain:GetArmyIndex()
    if type(category) == 'string' then
        testCat = ParseEntityCategory(category)
    end
    local eUnits = aiBrain:GetUnitsAroundPoint(testCat, Vector(0,0,0), 100000, 'Enemy')
    for k,v in eUnits do
        if v:GetAIBrain():GetArmyIndex() == enemyIndex then
            count = count + 1
        end
        if count > numReq then
            return true
        end
    end
    return false
end

##############################################################################################################
# function: EnemyInT3ArtilleryRange = BuildCondition
#
# parameter 0: string   aiBrain         = "default_brain"
# parameter 0: boolean  inrange         = "true = in range, false = not in range"
#
##############################################################################################################
function EnemyInT3ArtilleryRange(aiBrain, locationtype, inrange)
    local engineerManager = aiBrain.BuilderManagers[locationtype].EngineerManager
    if not engineerManager then
        return false
    end

    local start = engineerManager:GetLocationCoords()
    local factionIndex = aiBrain:GetFactionIndex()
    local radius = 0
    local offset = 0
    if factionIndex == 1 then
        radius = 825 + offset
    elseif factionIndex == 2 then
        radius = 825 + offset
    elseif factionIndex == 3 then
        radius = 825 + offset
    elseif factionIndex == 4 then
        radius = 825 + offset
    end
    for k,v in ArmyBrains do
        if not v.Result == "defeat" and not ArmyIsCivilian(v:GetArmyIndex()) and IsEnemy(v:GetArmyIndex(), aiBrain:GetArmyIndex()) then
            local estartX, estartZ = v:GetArmyStartPos()
            if (VDist2Sq(start[1], start[3], estartX, estartZ) <= radius * radius) and inrange then
                return true
            elseif (VDist2Sq(start[1], start[3], estartX, estartZ) > radius * radius) and not inrange then
                return true
            end
        end
    end
    return false
end

function AIOutnumbered(aiBrain, bool)
    local cheatmult = tonumber(ScenarioInfo.Options.CheatMult) or 2
    local buildmult = tonumber(ScenarioInfo.Options.BuildMult) or 2
    local cheatAdjustment = (cheatmult + buildmult) * .75
    local myTeam = ScenarioInfo.ArmySetup[aiBrain.Name].Team
    #LOG('*AI DEBUG: '..aiBrain.Nickname..' I am on team '..myTeam)
    local largestEnemyTeam = false
    local teams = {0,0,0,0,0,0,0,0}

    if aiBrain.CheatEnabled then
        teams[myTeam] = teams[myTeam] + (1 * cheatAdjustment)
    else
        teams[myTeam] = teams[myTeam] + 1
    end

    for k,v in ArmyBrains do
        if not v.Result == "defeat" and aiBrain:GetArmyIndex() ~= v:GetArmyIndex() and not ArmyIsCivilian(v:GetArmyIndex()) then
            local armyTeam = ScenarioInfo.ArmySetup[v.Name].Team
            #LOG('*AI DEBUG: '..v.Nickname..' is on team '..armyTeam)
            if v.CheatEnabled then
                teams[armyTeam] = teams[armyTeam] + (1 * cheatAdjustment)
            else
                teams[armyTeam] = teams[armyTeam] + 1
            end
        end
    end
    for x,z in teams do
        if z ~= myTeam and not largestEnemyTeam or z > largestEnemyTeam then
            largestEnemyTeam = z
        end
    end

    #LOG('*AI DEBUG: '..v.Nickname..' Larget enemy team is '..z..' strength')

    if largestEnemyTeam == 0 then
        return false
    elseif largestEnemyTeam > teams[myTeam] and bool then
        return true
    elseif largestEnemyTeam < teams[myTeam] and not bool then
        return true
    end
    return false
end

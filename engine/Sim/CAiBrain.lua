---@meta

---@class moho.aibrain_methods
local CAiBrain = {}

---@alias BrainArcType 'high' | 'low' | 'none'
---@alias BrainThreatType 'Overall' | 'OverallNotAssigned' | 'StructuresNotMex' | 'Structures' | 'Naval' | 'Air' | 'Land' | 'Experimental' | 'Commander' | 'Artillery' | 'AntiAir' | 'AntiSurface' | 'AntiSub' | 'Economy' | 'Unknown'

---@class BrainPositionThreat
---@field [1] number x
---@field [2] number z
---@field [3] number threat value


--- Assigns a threat value to a given position, which is applied to the iMAP threat grid
---@param position Vector
---@param threat number
---@param decay number
---@param threatType BrainThreatType
function CAiBrain:AssignThreatAtPosition(position, threat, decay, threatType)
end

--- Assigns a unit to a platoon
---@param platoon Platoon | string Either a reference to a platoon, or the unique name of the platoon
---@param unit Unit
---@param squad PlatoonSquads
---@param formation UnitFormations
function CAiBrain:AssignUnitsToPlatoon(platoon, unit, squad, formation)
end

--- Orders factories to build a platoon.
-- @param template Format: {name, plan, {bpID, min, max, squad, formation}, {...}, ...} .
-- @param factories Table of units-factories to build the platoon.
-- @param count How many times to built it.
function CAiBrain:BuildPlatoon(template, factories, count)
end

--- Order a unit to build a structure
---@param builder Unit
---@param blueprintID string
---@param buildLocation Vector
---@param buildRelative boolean if true, the location is used as an offset to the builders current location
function CAiBrain:BuildStructure(builder, blueprintID, buildLocation, buildRelative)
end

--- Order a factory to build a unit
---@param builder Unit
---@param unitToBuild string BlueprintId, as an example: `uel0303`
---@param count number
function CAiBrain:BuildUnit(builder, unitToBuild, count)
end

--- Filteres factories that can build the platoon and returns them.
-- Usually passed table with only one factory as AI picks the highest tech factory as a primary and others are assisting.
-- @param tempate Platoon's template.
-- @param factories Table containing units-factories.
-- @return tblUnits Table containing units-factories.
function CAiBrain:CanBuildPlatoon(template, factories)
end

--- Returns true if the structure can be built at the given location
---@param blueprintID string As an example: `ueb0101`
---@param location Vector
function CAiBrain:CanBuildStructureAt(blueprintID, location)
end

--- Returns true if the terrain is blocking weapon fire with the given arc from the attack position to the target position
---@param attackPosition Vector
---@param targetPosition Vector
---@param arcType BrainArcType
function CAiBrain:CheckBlockingTerrain(attackPosition, targetPosition, arcType)
end

--- Spawns a resource building near the given position, used for spawning the prebuild base
---@param blueprintID string
---@param posX number
---@param posY number
---@return Unit?
function CAiBrain:CreateResourceBuildingNearest(blueprintID, posX, posY)
end

--- Spawns a structure near the given position, used for spawning the prebuild base
---@param blueprintID string
---@param posX number
---@param posY number
---@return Unit?
function CAiBrain:CreateUnitNearSpot(blueprintID, posX, posY)
end

--- Returns UnitID for buildingType
-- @param builder Unit-engineer to build with.
-- @param buildingType Type of building (T1LandFactory, T4AirExperimental1, T1HydroCarbon etc)
-- @param buildingTemplate Table for each faction to get the UnitID for a buildingType
function CAiBrain:DecideWhatToBuild(builder, buildingType, buildingTemplate)
end

--- Disbands the platoon
---@param platoon Platoon
function CAiBrain:DisbandPlatoon(platoon)
end

--- Disbands the platoon via the unique name that a platoon can be accompanied by
---@param name string
function CAiBrain:DisbandPlatoonUniquelyNamed(name)
end

---@unknown
function CAiBrain:FindClosestArmyWithBase()
end
 
--- Find a free build place
-- @param buildingType Type of building (T1LandFactory, T4AirExperimental1, T1HydroCarbon etc)
-- @param whatToBuild UnitID
-- @param baseTemplate A default table with buildingTypes of all factions and searchpattern for a build place
-- @param relative true/false. true = build coordinates are relative to the starting location, false = absolute coords
-- @param closeToBuilder true/false. Build near the engineer or the base the engineer is part of.
-- @param optIgnoreAlliance nil/Enemy ignores enemy buildings like massextractors
-- @param BuildLocationX Position where we start to search for a free build area
-- @param BuildLocationZ
-- @param optIgnoreThreatUnder Ignores enemy threat under value
-- @return PlaceToBuild {x, z, y}
function CAiBrain:FindPlaceToBuild(buildingType, whatToBuild, baseTemplate, relative, closeToBuilder, optIgnoreAlliance, BuildLocationX, BuildLocationZ, optIgnoreThreatUnder)
end
--- Returns a unit that matches the categories, if available
---@param category EntityCategory
---@param needToBeIdle boolean
---@return Unit?
function CAiBrain:FindUnit(category, needToBeIdle)
end

--- Return a unit and it's upgrade blueprint.
-- TODO untested.
-- @param upgradeList Table, see '/lua/upgradetemplates.lua'.
-- @return TODO.

---@unknown
function CAiBrain:FindUnitToUpgrade(upgradeList)
end

--- Return an upgrade blueprint for the unit passed in.
-- @param unitName Blueprint ID of the unit to upgrade, example 'ueb0101'.
-- @param upgradeList Table, see '/lua/upgradetemplates.lua'.
-- @return BlueprintID, example 'ueb0201'
function CAiBrain:FindUpgradeBP(unitName, upgradeList)
end

--- Returns the ArmyIndex of the army represented by this brain.
-- @return Number.

--- Returns the army index
---@return number
function CAiBrain:GetArmyIndex()
end

--- Retrun army start position.
-- return x, z

--- Returns the army start position
---@return number X coordinate
---@return number Z coordinate
function CAiBrain:GetArmyStartPos()
end

--- Returns the relevant stat or default value.
-- @param statName String, name of the stats to get.
-- @param defaultValue Ff the stat doesn't exists, it creates it and returns this value.
-- @return Number.

--- Returns the statistic of the army, if it doesn't exist it creates it and returns the default value
---@param statName string
---@param defaultValue number | string | table
function CAiBrain:GetArmyStat(statName, defaultValue)
end

---@unknown
function CAiBrain:GetAttackVectors()
end

--- Returns a list of factories at a location
---@param location table table with location, it's not a position but location created by PBMAddBuildLocation function
---@param radius number
---@return FactoryUnit[]
function CAiBrain:GetAvailableFactories(location, radius)
end

--- Return a blueprint stat filtered by category.
-- @param statName String, name of the stats to get, example: "Enemies_Killed".
-- @param category Unit's category, example: categories.TECH2 .
-- @return Number.
function CAiBrain:GetBlueprintStat(statName, category)
end

--- Return this brain's current enemy.
-- @return Number, target's army number.
function CAiBrain:GetCurrentEnemy()
end

--- Return how many units of the given categories exist.
-- @param category Unit's category, example: categories.TECH2 .
-- @return Number.

--- Returns the number of units of the given categories
---@param category EntityCategory
---@return number
function CAiBrain:GetCurrentUnits(category)
end

--- Returns current resource income.
-- @param resource 'ENERGY' or 'MASS'.
-- @return Number.
function CAiBrain:GetEconomyIncome(resource)
end

--- Return how much of the resource the brains wants to use.
-- This is used for calculating Paragon's production.
-- @param resource 'ENERGY' or 'MASS'.
-- @return Number.
function CAiBrain:GetEconomyRequested(resource)
end

--- Return current resource amout in storage.
-- @param resource 'ENERGY' or 'MASS'.
-- @return Number.
function CAiBrain:GetEconomyStored(resource)
end

--- Returns the ratio between resource in storage to maximum storage amout.
-- @param resource 'ENERGY' or 'MASS'.
-- @return Float Number 0.0 - 1
function CAiBrain:GetEconomyStoredRatio(resource)
end

--- Returns the relative resource income. (production - usage)
---@param resource 'ENERGY'|'MASS'.
---@return number  (0.1 = 1)
function CAiBrain:GetEconomyTrend(resource)
end

--- Returns current resource usage.
-- When stalling, this number is same as the current income.
---@param resource 'ENERGY' | 'MASS'
---@return number
function CAiBrain:GetEconomyUsage(resource)
end

--- Returns the faction of the army represented by this brain.
-- 1 UEF, 2 Aeon, 3 Cybran, 4 Seraphim. 5 custom faction like Nomads
---@return number
function CAiBrain:GetFactionIndex()
end

--- Returns a position with highest threat and the threat value.
--- Always reports a threatvalue of zero for Allies or self.
--- threatType and armyIndex are not required.
--- @param ring number 1 or 2
--- 1 = Single, 2 = With surrounding IMPA blocks 
--- ..........   ..........
--- ..........   ....xxx...
--- .....X....   ....xXx...
--- ..........   ....xxx...
--- ..........   ..........
---@param restriction boolean
---@param threatType BrainThreatType
---@param armyIndex number defaults to use all enemy armies.
---@return Vector
---@return number
function CAiBrain:GetHighestThreatPosition(ring, restriction, threatType, armyIndex)
end

--- Returns a list of units that match the categories
---@param category EntityCategory
---@param needToBeIdle boolean
---@param requireBuilt boolean Appears to be not functional
---@return Unit[]
function CAiBrain:GetListOfUnits(category, needToBeIdle, requireBuilt)
end

--- Returns a ratio between water and land.
---@return number 0.0 - 1.0
function CAiBrain:GetMapWaterRatio()
end

--- TODO. Number of no rush ticks left
---@return number
function CAiBrain:GetNoRushTicks()
end

--- TODO.
-- Probably has to do something with first param of MakePlatoon().
---@return number
function CAiBrain:GetNumPlatoonsTemplateNamed()
end

--- TODO.
---@return Number
function CAiBrain:GetNumPlatoonsWithAI()
end

--- Returns the number of units around a position that match the categories
---@param category EntityCategory
---@param position Vector
---@param radius number
---@param alliance AllianceStatus
---@return number
function CAiBrain:GetNumUnitsAroundPoint(category, position, radius, alliance)
end

--- Return the personality for this brain to use.
-- @return AIPersonalityTemplate from aipersonality.lua
function CAiBrain:GetPersonality()
end

--- Returns platoon by unique name.
---@param name string unique platoon's name set by platoon:UniquelyNamePlatoon(name) function.
---@return Platoon
function CAiBrain:GetPlatoonUniquelyNamed(name)
end

--- Returns brain's platoons
-- @return tblPlatoons Table containing platoons.
function CAiBrain:GetPlatoonsList()
end

--- Returns threat at given position
---@param position Vector
---@param radius number in game units
---@param restriction boolean
---@param threatType BrainThreatType
---@param armyIndex? number defaults to this brain's index
---@return number
function CAiBrain:GetThreatAtPosition(position, radius, restriction, threatType, armyIndex)
end

--- Returns threat between two positions
---@param position Vector
---@param position2 Vector
---@param restriction boolean
---@param threatType BrainThreatType
---@param armyIndex? number defaults to this brain's index
---@return number
function CAiBrain:GetThreatBetweenPositions(position, position2, restriction, threatType, armyIndex)
end

--- Returns threats around position
---@param position Vector
---@param radius number in game units
---@param restriction boolean
---@param threatType BrainThreatType
---@param armyIndex number
---@return BrainPositionThreat[]
function CAiBrain:GetThreatsAroundPosition(position, radius, restriction, threatType, armyIndex)
end

--- Returns unit blueprint if given blueprint name
---@param bpName string Example 'ual0201'.
---@return UnitBlueprint
function CAiBrain:GetUnitBlueprint(bpName)
end

--- Return list of units around position.
-- @param category Unit's category, example: categories.TECH2 .
-- @param position Table with position {x, y, z}.
-- @param radius Number in game units.
-- @param alliance Types: 'Ally', 'Enemy', 'Neutral'.
-- @return tblUnits Table containing units.

--- Returns the units around a position that match the categories
---@param category EntityCategory
---@param position Vector
---@param radius number
---@param alliance AllianceType
function CAiBrain:GetUnitsAroundPoint(category, position, radius, alliance)
end

--- Gives resources to brain.
-- @param type 'Energy', 'Mass'.
-- @param amout Number, how much to give.
function CAiBrain:GiveResource(type, amount)
end

--- Gives storage to brain.
-- @param type 'Energy', 'Mass'.
-- @param amout Number, how much to give.
function CAiBrain:GiveStorage(type, amount)
end

--- TODO.
function CAiBrain:IsAnyEngineerBuilding(category)
end

--- Returns true if opponent AI should be running.
-- @return true/false (not used in FAF)
function CAiBrain:IsOpponentAIRunning()
end

--- Creates a new platoon.
-- @param name or '', custom platoon name
-- @param aiPlan Plan to follow for this platoon or '', the function for the plan is in '/lua/platoon.lua'.
-- @return Platoon.
function CAiBrain:MakePlatoon(name, aiPlan)
end

--- Return number of unit's categories being built.
-- @param entityCategoryOfBuildee Unit's category that is being built.
-- @param entityCategoryOfBuilder Unit's category of the unit building, example: categories.CONSTRUCTION .
-- @return Number.
function CAiBrain:NumCurrentlyBuilding(entityCategoryOfBuildee, entityCategoryOfBuilder)
end

--- TODO.
function CAiBrain:PickBestAttackVector()
end

--- Returns true if platoon exists.
-- @return true/false.
function CAiBrain:PlatoonExists(platoon)
end

--- Remove an army stats trigger.
-- @param statName String, army's stat, example: "Economy_Ratio_Mass".
-- @param triggerName String, unique name of the trigger.
function CAiBrain:RemoveArmyStatsTrigger(statName, triggerName)
end

--- Sets army's stat to value.
-- @param statName String, army's stat, example: "Economy_Ratio_Mass".
-- @param value Number.
function CAiBrain:SetArmyStat(statName, value)
end

--- Creates a new stat trigger.
-- @param statName String, army's stat, example: "Economy_Ratio_Mass".
-- @param triggerName String, unique name of the trigger.
-- @param compareType String, available types: 'LessThan', 'LessThanOrEqual', 'GreaterThan', 'GreaterThanOrEqual', 'Equal'.
-- @param value Number.
function CAiBrain:SetArmyStatsTrigger(statName, triggerName, compareType, value)
end

--- Set the current enemy for this brain to attack.
-- @param armyIndex Target's army number.
function CAiBrain:SetCurrentEnemy(armyIndex)
end

--- Set the current plan for this brain to run.
-- TODO.
function CAiBrain:SetCurrentPlan()
end

--- TODO.
function CAiBrain:SetGreaterOf(statname, val)
end

--- Set if the brain should share resources to the allies.
-- @param bool ture/false
function CAiBrain:SetResourceSharing(bool)
end

--- TODO.
function CAiBrain:SetUpAttackVectorsToArmy(category)
end

--- Removes resources from brain.
-- @param type 'Energy', 'Mass'.
-- @param amout Number, how much to take.
function CAiBrain:TakeResource(type, amount)
end

return CAiBrain

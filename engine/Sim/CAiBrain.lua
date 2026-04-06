---@meta

---@class moho.aibrain_methods
local CAiBrain = {}

---@alias BrainArcType 'high' | 'low' | 'none'
---@alias BrainThreatType 'Overall' | 'OverallNotAssigned' | 'StructuresNotMex' | 'Structures' | 'Naval' | 'Air' | 'Land' | 'Experimental' | 'Commander' | 'Artillery' | 'AntiAir' | 'AntiSurface' | 'AntiSub' | 'Economy' | 'Unknown'

---@class BrainPositionThreat
---@field [1] number x
---@field [2] number z
---@field [3] number threat value

---@class BuildingTemplate
---@field [1] string[] # builder types
---@field [2] Vector2
-- @field [...] Vector2

---@alias TemplateBuilderTypeResources "Resource" | "T1Resource" | "T2Resource" | "T3Resource" | "T1HydroCarbon"

--- Assigns a threat value to a given position, which is applied to the iMAP threat grid
---@param position Vector
---@param threat number
---@param decay number
---@param threatType BrainThreatType
function CAiBrain:AssignThreatAtPosition(position, threat, decay, threatType)
end

--- Assigns a unit to a platoon
---@param platoon moho.platoon_methods | string Either a reference to a platoon, or the unique name of the platoon
---@param unit Unit
---@param squad PlatoonSquads
---@param formation UnitFormations
function CAiBrain:AssignUnitsToPlatoon(platoon, unit, squad, formation)
end

--- Orders factories to build a platoon.
---@param template table # Format: {name, plan, {bpID, min, max, squad, formation}, {...}, ...} .
---@param factories Unit[] # Table of units-factories to build the platoon.
---@param count number # How many times to built it.
function CAiBrain:BuildPlatoon(template, factories, count)
end

--- Order a unit to build a structure
---@param builder Unit
---@param blueprintID UnitId
---@param buildLocation Vector
---@param buildRelative? boolean if true, the location is used as an offset to the builders current location
function CAiBrain:BuildStructure(builder, blueprintID, buildLocation, buildRelative)
end

--- Order a factory to build a unit
---@param builder Unit
---@param unitToBuild UnitId BlueprintId, as an example: `uel0303`
---@param count number
function CAiBrain:BuildUnit(builder, unitToBuild, count)
end

--- Filteres factories that can build the platoon and returns them.
-- Usually passed table with only one factory as AI picks the highest tech factory as a primary and others are assisting.
---@param template table # Platoon's template.
---@param factories table # containing units-factories.
---@return table tblUnits # containing units-factories.
function CAiBrain:CanBuildPlatoon(template, factories)
end

--- Returns true if the structure can be built at the given location. May return false positives
---@param blueprintID string As an example: `ueb0101`
---@param location Vector
---@return boolean
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
---@param builder Unit # engineer to build with.
---@param buildingType string # Type of building (T1LandFactory, T4AirExperimental1, T1HydroCarbon etc)
---@param buildingTemplate table # table for each faction to get the UnitID for a buildingType
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

--- Takes a builder and returns the closest point that the structure can be
--- built at in the list of building templates with matching builder types.
---
--- Let `startLocation` be the army start position, or the offset override if
--- present.
--- Let `targetLocation` be the builder's location (or the army start if somehow
--- nil), or the offset overide if present.
--- For each template:
---    Let each points' location be `templateLocation`, added with
---    `startLocation` if `relative` is true.
---    It is considered if `structureName` can be built at this location and,
---    If `optIgnoreThreatOver` is above 0.0, the anti-surface threat influence
---    (calculated using ring=0) is less than `optIgnoreThreatOver`.
--- The point with the small distance between `templateLocation` and
--- `targetLocation` is returned.
---
--- If the builder type is one of `TemplateBuilderTypeResources` (and the
--- "/nomass" commandline switch is absent), distance is calculated between
--- `startingLocation` and all nearby deposits (mass points, unless the
--- structure blueprint has the `"HYDROCARBON"` category) are queried and no
--- points in the template are used.
---
---@param type string
---@param structureName FileName # blueprint file
---@param buildingTypes BuildingTemplate[]
---@param relative boolean
---@param builder Unit
---@param optIgnoreAlliance? AllianceType # defaults to `nil`
---@param optOverridePosX? number # defaults to 0.0; ignored if `optOverridePosZ` is absent
---@param optOverridePosZ? number # defaults to 0.0
---@param optIgnoreThreatOver? integer # defaults to 0 (accept all)
---@return Vector2 location # a new table of `{x, z, 0}` for resource builder types, the actual point otherwise
function CAiBrain:FindPlaceToBuild(type, structureName, buildingTypes, relative, builder, optIgnoreAlliance, optOverridePosX, optOverridePosZ, optIgnoreThreatOver)
end

--- Returns a unit that matches the categories, if available
---@param category EntityCategory
---@param needToBeIdle boolean
---@return Unit?
function CAiBrain:FindUnit(category, needToBeIdle)
end

--- Return a unit and it's upgrade blueprint.
--- TODO untested.
---@param upgradeList UnitUpgradeTemplates # Table, see '/lua/upgradetemplates.lua'.
---@return any # TODO.
function CAiBrain:FindUnitToUpgrade(upgradeList)
end

--- Return an upgrade blueprint for the unit passed in.
---@param unitName UnitId # ID of the unit to upgrade, example 'ueb0101'.
---@param upgradeList table # Table, see '/lua/upgradetemplates.lua'.
---@return UnitId # example 'ueb0201'
function CAiBrain:FindUpgradeBP(unitName, upgradeList)
end

--- Returns the ArmyIndex of the army represented by this brain.
---@return number

--- Returns the army index
---@return integer
function CAiBrain:GetArmyIndex()
end

--- Retrun army start position.
-- return x, z

--- Returns the army start position
---@return number Xcoordinate
---@return number Zcoordinate
function CAiBrain:GetArmyStartPos()
end

---@alias AIBrainBlueprintStatEconomy
--- | 'Economy_TotalProduced_Energy'
--- | 'Economy_TotalConsumed_Energy'
--- | 'Economy_Income_Energy'
--- | 'Economy_Output_Energy'
--- | 'Economy_Stored_Energy'
--- | 'Economy_Reclaimed_Energy'
--- | 'Economy_Ratio_Energy'
--- | 'Economy_MaxStorage_Energy'
--- | 'Economy_Trend_Energy'
--- | 'Economy_PeakStorage_Energy'
--- | 'Economy_TotalProduced_Mass'
--- | 'Economy_TotalConsumed_Mass'
--- | 'Economy_Income_Mass'
--- | 'Economy_Output_Mass'
--- | 'Economy_Stored_Mass'
--- | 'Economy_Reclaimed_Mass'
--- | 'Economy_Ratio_Mass'
--- | 'Economy_MaxStorage_Mass'
--- | 'Economy_Trend_Mass'
--- | 'Economy_PeakStorage_Mass'

--- Returns the statistic of the army, if it doesn't exist it creates it and returns the default value
---@see CAiBrain:GetBlueprintStat(...) for army related statistics
---@param statName AIBrainBlueprintStatEconomy
---@param defaultValue number | string | table
function CAiBrain:GetArmyStat(statName, defaultValue)
end

---@unknown
function CAiBrain:GetAttackVectors()
end

--- Returns a list of factories at a location
---@param location? table table with location, it's not a position but location created by PBMAddBuildLocation function
---@param radius? number
---@return FactoryUnit[]
function CAiBrain:GetAvailableFactories(location, radius)
end

---@alias AIBrainBlueprintStatUnits
--- | 'Units_History'
--- | 'Units_Killed'
--- | 'Units_BeingBuilt'
--- | 'Units_Active'
--- | 'Units_TotalDamageDealt'
--- | 'Units_TotalDamageReceive'

---@alias AIBrainBlueprintStatEnemies
--- | 'Enemies_Killed'
--- | 'Enemies_MassValue_Destroyed'
--- | 'Enemies_EnergyValue_Destroyed'
--- | 'Enemies_Commanders_Destroyed'

---@alias AIBrainBlueprintStatDamage
--- | 'DamageStats_TotalDamageReceived'
--- | 'DamageStats_TotalDamageDealt'

--- Return a blueprint stat filtered by category.
---@see CAiBrain:GetArmyStat(...) for army related statistics
---@param statName AIBrainBlueprintStatUnits | AIBrainBlueprintStatEnemies | AIBrainBlueprintStatEconomy | AIBrainBlueprintStatDamage
---@param category EntityCategory 's category, example: categories.TECH2 .
---@return number
function CAiBrain:GetBlueprintStat(statName, category)
end

--- Return this brain's current enemy.
---@return number -- target army's number
function CAiBrain:GetCurrentEnemy()
end

--- Returns the number of units of the given categories
---@param category EntityCategory
---@return number
function CAiBrain:GetCurrentUnits(category)
end

--- Returns current income per tick of the resouce.
---@param resource 'ENERGY'|'MASS'
---@return number
function CAiBrain:GetEconomyIncome(resource)
end

--- Returns how much of the resource the brain wants to use per tick.
--- This is used for calculating Paragon's production.
---@param resource 'ENERGY'|'MASS'
---@return number
function CAiBrain:GetEconomyRequested(resource)
end

--- Return current resource amout in storage.
---@param resource 'ENERGY'|'MASS'
---@return number
function CAiBrain:GetEconomyStored(resource)
end

--- Returns the ratio between resource in storage to maximum storage amout.
---@param resource 'ENERGY' | 'MASS'
---@return number
function CAiBrain:GetEconomyStoredRatio(resource)
end

--- Returns the relative resource income. (production - usage)
---@param resource 'ENERGY'|'MASS'
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
----@param ring number 1 or 2
--- 1 = Single, 2 = With surrounding IMPA blocks
--- ..........   ..........
--- ..........   ....xxx...
--- .....X....   ....xXx...
--- ..........   ....xxx...
--- ..........   ..........
---@param restriction boolean
---@param threatType? BrainThreatType
---@param armyIndex? number defaults to use all enemy armies.
---@return Vector
---@return number
function CAiBrain:GetHighestThreatPosition(ring, restriction, threatType, armyIndex)
end

--- Returns a list of units that match the categories.
---
--- This function does **not** take into account intel.
---@param category EntityCategory
---@param needToBeIdle boolean
---@param requireBuilt boolean Appears to be not functional
---@return Unit[]
function CAiBrain:GetListOfUnits(category, needToBeIdle, requireBuilt)
end

--- Returns a ratio between water and land.
---@return number # 0.0 - 1.0
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
---@return number
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
---@return AIPersonality
function CAiBrain:GetPersonality()
end

--- Returns platoon by unique name.
---@param name string unique platoon's name set by platoon:UniquelyNamePlatoon(name) function.
---@return Platoon
function CAiBrain:GetPlatoonUniquelyNamed(name)
end

--- Returns brain's platoons
---@return Platoon[]
function CAiBrain:GetPlatoonsList()
end

--- Returns threat at given position
---@param position Vector
---@param radius number in game units
---@param restriction boolean
---@param threatType? BrainThreatType
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
---@param armyIndex number?
---@return BrainPositionThreat[]
function CAiBrain:GetThreatsAroundPosition(position, radius, restriction, threatType, armyIndex)
end

--- Returns unit blueprint if given blueprint name
---@param bpName string Example 'ual0201'.
---@return UnitBlueprint
function CAiBrain:GetUnitBlueprint(bpName)
end

--- Returns the units around a position that match the categories.
---
--- This function takes into account intel.
---@param category EntityCategory
---@param position Vector
---@param radius number
---@param alliance? AllianceType
---@return Unit[]
function CAiBrain:GetUnitsAroundPoint(category, position, radius, alliance)
end

--- Gives resources to brain.
---@param type 'ENERGY' | 'MASS'
---@param amount number
function CAiBrain:GiveResource(type, amount)
end

--- Gives storage to brain.
---@param type 'ENERGY' | 'MASS'
---@param amount number
function CAiBrain:GiveStorage(type, amount)
end

--- Returns true when any engineer is building something of the given category
---@param category EntityCategory
---@return boolean
function CAiBrain:IsAnyEngineerBuilding(category)
end

---@deprecated not used in faf
--- Returns true if opponent AI should be running.
---@return boolean
function CAiBrain:IsOpponentAIRunning()
end

--- Creates a new platoon.
---@param name string # unique name for platoon
---@param aiPlan string # to follow for this platoon or '', the function for the plan is in '/lua/platoon.lua'.
---@return Platoon
function CAiBrain:MakePlatoon(name, aiPlan)
end

--- Returns number of units of a given category building units of another given category
---@param entityCategoryOfBuildee EntityCategory # Category of unit that is being built
---@param entityCategoryOfBuilder EntityCategory # Category of unit that is building
---@return number
function CAiBrain:NumCurrentlyBuilding(entityCategoryOfBuildee, entityCategoryOfBuilder)
end

---TODO.
---@param platoon Platoon
---@param squad PlatoonSquads
---@param alliance AllianceType
---@param category EntityCategory
---@param compareType any
---@return Vector
function CAiBrain:PickBestAttackVector(platoon, squad, alliance, category, compareType)
end

--- Returns true if platoon exists.
---@param platoon Platoon
---@return boolean
function CAiBrain:PlatoonExists(platoon)
end

--- Remove an army stats trigger.
---@param statName AIBrainBlueprintStatUnits | AIBrainBlueprintStatEnemies | AIBrainBlueprintStatEconomy | AIBrainBlueprintStatDamage
---@param triggerName string # unique name of the trigger.
function CAiBrain:RemoveArmyStatsTrigger(statName, triggerName)
end

--- Sets army's stat to value.
---@param statName AIBrainBlueprintStatUnits | AIBrainBlueprintStatEnemies | AIBrainBlueprintStatEconomy | AIBrainBlueprintStatDamage # army's stat, example: "Economy_Ratio_Mass".
---@param value number
function CAiBrain:SetArmyStat(statName, value)
end

---@alias ComparatorString
---| "LessThan"
---| "LessThanOrEqual"
---| "GreaterThan"
---| "GreaterThanOrEqual"
---| "Equal"

--- Creates a new stat trigger.
---@param statName AIBrainBlueprintStatUnits | AIBrainBlueprintStatEnemies | AIBrainBlueprintStatEconomy | AIBrainBlueprintStatDamage # army's stat
---@param triggerName string # unique name of the trigger. See `RemoveArmyStatsTrigger` to remove occupied names.
---@param compareType ComparatorString # available types: `LessThan`, `LessThanOrEqual`, `GreaterThan`, `GreaterThanOrEqual`, `Equal`
---@param value number #
---@param category EntityCategory? #
function CAiBrain:SetArmyStatsTrigger(statName, triggerName, compareType, value, category)
end

--- Set the current enemy for this brain to attack.
---@param armyIndex Army
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
---@param bool boolean
function CAiBrain:SetResourceSharing(bool)
end

--- TODO.
function CAiBrain:SetUpAttackVectorsToArmy(category)
end

--- Removes resources from brain.
---@param type 'ENERGY' | 'MASS'
---@param amount number # how much to take.
---@return number # actual amount taken
function CAiBrain:TakeResource(type, amount)
end

return CAiBrain

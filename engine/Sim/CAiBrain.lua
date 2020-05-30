--- Class CAiBrain
-- @classmod Sim.CAiBrain

--- Assigns threat value to given position.
-- Threat is used for calculation where to attack with unit.
-- Or what place to avoid with engineers.
-- @param position Table with position {x, y z}.
-- @param threat Number reptresenting the threat.
-- @param decay Number, the thread is decreasing by time.
-- @param threatType Types: TODO.
function CAiBrain:AssignThreatAtPosition(position, threat, [decay], [threatType])
end

--- Assign unit to platoon.
-- If the unit is already in a platoon, it gets removed from it.
-- @param platoon Either platoon or string with platoon's unique name.
-- @param unit Unit to assign.
-- @param squad Platoon's squad to assign the unit to, types: 'Attack', 'Artillery', 'Guard' 'None', 'Scout', 'Support', 'Unassigned'.
-- @param formation Types: 'AttackFormation', 'GrowthFormation', 'NoFormation'.
function CAiBrain:AssignUnitsToPlatoon(platoon, unit, squad, formation)
end

--- Orders factories to build a platoon.
-- @param template Format: {name, plan, {bpID, min, max, squad, formation}, {...}, ...} .
-- @param factories Table of units-factories to build the platoon.
-- @param count How many times to built it.
function CAiBrain:BuildPlatoon(template, factories, count)
end

--- Orders the builder to build a unit.
-- @param builder Unit, (engineer) to use.
-- @param blueprintID Unit's bp ID to build, example: 'ueb0101'.
-- @param buildLocation Table {x, z, 0}.
-- @param buildRelative: true/false. true = build coordinates are relative to the starting location, false = absolute coords
-- @return true/false
function CAiBrain:BuildStructure(builder, blueprintID, buildLocation, buildRelative)
end

--- Orders a mobile factory to build a unit.
-- @param builder Unit, mobile factory.
-- @param unitToBuild BlueprintID of unit to build, example 'uel0303'.
-- @param count Number, how many units to build.
function CAiBrain:BuildUnit(builder, unitToBuild, count)
end

--- Filteres factories that can build the platoon and returns them.
-- Usually passed table with only one factory as AI picks the highest tech factory as a primary and others are assisting.
-- @param tempate Platoon's template.
-- @param factories Table containing units-factories.
-- @return tblUnits Table containing units-factories.
function CAiBrain:CanBuildPlatoon(template, factories)
end

--- Returns true if structure can be built at given location.
-- @param blueprintID Unit's bp ID to build, example 'ueb0101'.
-- @param location Table with position {x, y z}.
-- @return true/false
function CAiBrain:CanBuildStructureAt(blueprintID, location)
end

--- TODO.
-- @param startPos  Table with position {x, y z}, current position.
-- @param endPos position Table with position {x, y z}, desired position.
-- @param arcType Types: 'high', 'low', 'none'.
-- @return true/false
function CAiBrain:CheckBlockingTerrain(startPos, endPos, arcType)
end

--- Spawns a resource building near position.
-- Used for spawning prebuild base resource structures.
-- @param blueprintID Unit's bp ID to spawn, example 'ueb0101'.
-- @param posX Position on X axis.
-- @param posY Position on Z axis (wrong name, also named like this in the functions that uses it, but it actually is the Z axis as Y is elevation).
-- @return Spawned unit or nil.
function CAiBrain:CreateResourceBuildingNearest(blueprintID, posX, posY)
end

--- Spawn a structure near position.
-- Used for spawning prebuild base.
-- @param blueprintID Unit's bp ID to spawn, example 'ueb0101'.
-- @param posX Position on X axis.
-- @param posY Position on Z axis (wrong name, also named like this in the functions that uses it, but it actually is the Z axis as Y is elevation).
-- @return Spawned unit or nil.
function CAiBrain:CreateUnitNearSpot(blueprintID, posX, posY).
end

--- TODO.
-- @param builder Unit-engineer to build with.
-- @param type
-- @param buildingTypes
function CAiBrain:DecideWhatToBuild(builder, type, buildingTypes)
end

--- Disbands a given platoon.
-- @param platoon Platoon to disband.
function CAiBrain:DisbandPlatoon(platoon)
end

--- Disbands a given platoon.
-- @param name Unique name of a platoon to disband.
function CAiBrain:DisbandPlatoonUniquelyNamed(name)
end

--- TODO.
function CAiBrain:FindClosestArmyWithBase()
end

--- TODO.
-- @return x, z, distance
function CAiBrain:FindPlaceToBuild(type, structureName, buildingTypes, relative, builder, optIgnoreAlliance, optOverridePosX, optOverridePosZ, optIgnoreThreatOver)
end

--- Return an unit that matches the unit name.
-- Can specify idle or not.
-- @param category Unit's category, example: categories.TECH2 * categories.ENGINEER .
-- @param needToBeIdle true/false.
-- @return Unit.
function CAiBrain:FindUnit(category, needToBeIdle)
end

--- Return a unit and it's upgrade blueprint.
-- TODO untested.
-- @param upgradeList Table, see '/lua/upgradetemplates.lua'.
-- @return TODO.
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
function CAiBrain:GetArmyIndex()
end

--- Retrun army start position.
-- return x, z
function CAiBrain:GetArmyStartPos()
end

--- Returns the relevant stat or default value.
-- @param statName String, name of the stats to get.
-- @param defaultValue Ff the stat doesn't exists, it creates it and returns this value.
-- @return Number.
function CAiBrain:GetArmyStat(statName, defaultValue)
end

--- TODO.
function CAiBrain:GetAttackVectors()
end

--- Returns list of factories at location.
-- @param location Table with location, it's not a position but location created by PBMAddBuildLocation function.
-- @param radius Number in game units.
-- @return tblUnits List of factories.
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
function CAiBrain:GetCurrentUnits(category)
end

--- Returns current resource income.
-- @param resource 'Energy' or 'Mass'.
-- @return Number.
function CAiBrain:GetEconomyIncome(resource)
end

--- Return how much of the resource the brains wants to use.
-- This is used for calculating Paragon's production.
-- @param resource 'Energy' or 'Mass'.
-- @return Number.
function CAiBrain:GetEconomyRequested(resource)
end

--- Return current resource amout in storage.
-- @param resource 'Energy' or 'Mass'.
-- @return Number.
function CAiBrain:GetEconomyStored(resource)
end

--- Returns the ratio between resource in storage to maximum storage amout.
-- @param resource 'Energy' or 'Mass'.
-- @return Float Number 0.0 - 1
function CAiBrain:GetEconomyStoredRatio(resource)
end

--- TODO.
-- @param resource 'Energy' or 'Mass'.
-- @return TODO.
function CAiBrain:GetEconomyTrend(resource)
end

--- Returns current resource usage.
-- When stalling, this number is same as the current income.
-- @param resource 'Energy' or 'Mass'.
-- @return Number.
function CAiBrain:GetEconomyUsage(resource)
end

--- Returns the faction of the army represented by this brain.
-- 1 UEF, 2 Aeon, 3 Cybran, 4 Seraphim.
-- @return Number.
function CAiBrain:GetFactionIndex()
end

--- Returns a position with highest threat and the threat value.
-- Always reports a threatvalue of zero for Allies or self.
-- threatType and armyIndex are not required.
-- @param ring Number, in game unit.
-- @param restriction TODO.
-- @param threatType TODO Find out all threat types.
-- @param armyIndex Army's number, if not specified, uses all enemy armies.
-- @return position, value Position table {x, y, z}, value Number.
function CAiBrain:GetHighestThreatPosition(ring, restriction, threatType, armyIndex)
end

--- Returns list of units by category.
-- @param category Unit's category, example: categories.TECH2 .
-- @param needToBeIdle true/false Unit has to be idle.
-- @param requireBuilt true/false defaults to false which excludes units that are NOT finished.
-- @return tblUnits Table containing units.
function CAiBrain:GetListOfUnits(category,  needToBeIdle,  requireBuilt)
end

--- Returns a ratio between water and land.
-- @return Float number 0.0 - 1.
function CAiBrain:GetMapWaterRatio()
end

--- TODO. Number of no rush ticks left?
-- @return Number.
function CAiBrain:GetNoRushTicks()
end

--- TODO.
-- Probably has to do something with first param of MakePlatoon().
-- @return Number.
function CAiBrain:GetNumPlatoonsTemplateNamed()
end

--- TODO.
-- @return Number.
function CAiBrain:GetNumPlatoonsWithAI()
end

--- Return number of units around position.
-- @param category Unit's category, example: categories.TECH2 .
-- @param position Table with position {x, y, z}.
-- @param radius Number in game units.
-- @param alliance Types: 'Ally', 'Enemy', 'Neutral'.
-- @return Number.
function CAiBrain:GetNumUnitsAroundPoint(category, position, radius, alliance)
end

--- Return the personality for this brain to use.
-- @return TODO.
function CAiBrain:GetPersonality()
end

--- Returns platoon by unique name.
-- @param name String, unique platoon's name set by platoon:UniquelyNamePlatoon(name) function.
-- @return platoon
function CAiBrain:GetPlatoonUniquelyNamed(name)
end

--- Returns brain's platoons.
-- @return tblPlatoons Table containing platoons.
function CAiBrain:GetPlatoonsList()
end

--- Returns threat at given position.
-- @param position Table with position {x, y, z}.
-- @param radius Number in game units.
-- @param restriction TODO.
-- @param threatType TODO.
-- @param armyIndex Army's number, if specified uses, only this brain.
-- @return Number.
function CAiBrain:GetThreatAtPosition(position, radius, restriction, threatType, armyIndex)
end

--- Returns threat between two positions.
-- @param position Table with position {x, y, z}.
-- @param position2 Table with position {x, y, z}.
-- @param restriction
-- @param threatType
-- @param armyIndex Army's number, if specified uses, only this brain.
-- @return Number.
function CAiBrain:GetThreatBetweenPositions(position, position2, restriction, threatType, armyIndex)
end

--- Return threats around position.
-- @param position Table with position {x, y, z}.
-- @param radius Number in game units.
-- @param restriction
-- @param threatType
-- @param armyIndex
-- @return Table {{x, z, threatValue}, {...}, ...}.
function CAiBrain:GetThreatsAroundPosition(position, radius, restriction, threatType, armyIndex)
end

--- Returns unit blueprint if given blueprint name.
-- @param bpName Example 'ual0201'.
-- @return Blueprint.
function CAiBrain:GetUnitBlueprint(bpName)
end

--- Return list of units around position.
-- @param category Unit's category, example: categories.TECH2 .
-- @param position Table with position {x, y, z}.
-- @param radius Number in game units.
-- @param alliance Types: 'Ally', 'Enemy', 'Neutral'.
-- @return tblUnits Table containing units.
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
-- @return true/false
function CAiBrain:IsOpponentAIRunning()
end

--- Creates a new platoon.
-- @param name or '', This is NOT platoon's unique name. TODO: probably template's name.
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
-- TODO.
function CAiBrain:RemoveArmyStatsTrigger()
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

---
--
function CAiBrain:moho.aibrain_methods()
end


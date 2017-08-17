--- Class CPlatoon
-- @classmod Sim.CPlatoon

--- Orders platoon to attack target unit.
-- If squad is specified, attacks only with the squad.
-- @param target Unit to attack.
-- @param squad Types: 'Attack', 'Artillery', 'Guard' 'None', 'Scout', 'Support'.
-- @return command
function CPlatoon:AttackTarget(target, squad)
end

--- Orders platoon to attack mote to target position..
-- If squad is specified, attack moves only with the squad.
-- @param position Table with position {x, y, z}.
-- @param squad Types: 'Attack', 'Artillery', 'Guard' 'None', 'Scout', 'Support'.
-- @return command
function CPlatoon:AggressiveMoveToLocation(position, squad)
end

--- TODO.
-- @return Number
function CPlatoon:CalculatePlatoonThreat(threatType, category)
end

--- TODO.
-- @param threatType TODO. Examples: 'AntiSurface', 'AntiAir', 'Overall'.
-- @param category Unit's category, example: categories.TECH2 .
-- @param position Table with position {x, y, z}.
-- @param radius Radius in game units.
-- @return Number
function CPlatoon:CalculatePlatoonThreatAroundPosition(threatType, category, position, radius)
end

--- Returns true if squad can attack target unit.
-- @param target Unit to check.
-- @param squad Types: 'Attack', 'Artillery', 'Guard' 'None', 'Scout', 'Support'.
-- @return true/false
function CPlatoon:CanAttackTarget(squad, target)
end

--- TODO.
-- @return true/false
function CPlatoon:CanConsiderFormingPlatoon()
end

--- TODO.
-- Example: local formIt = poolPlatoon:CanFormPlatoon(template, personality:GetPlatoonSize(), self.Location, radius)
-- @return true/false
function CPlatoon:CanFormPlatoon()
end

--- Destroys the platoon including all its units.
function CPlatoon:Destroy()
end

--- Disband the platoon once it gets into the Idle state.
function CPlatoon:DisbandOnIdle()
end

--- Orders platoon to create ferry route to target location.
-- Can be called several times to create a non linear route.
-- @param position Table with position {x, y, z}.
-- @return command
function CPlatoon:FerryToLocation(position)
end

--- Returns closest unit to the platoon's squad.
-- Example: FindClosestUnit('Attack', 'Enemy', true, categories.ALLUNITS - categories.WALL).
-- @param squad Types: 'Attack', 'Artillery', 'Guard' 'None', 'Scout', 'Support'.
-- @param alliance Target alliance, types: 'Ally, 'Enemy', 'Neutral'.
-- @param canAttack true/false if the squad has to be able to attack the unit.
-- @param category Target unit category, example: categories.TECH2 .
-- @return Unit.
function CPlatoon:FindClosestUnit(squad, alliance, canAttack, category)
end

--- TODO.
-- Needs 4 parametrs.
function CPlatoon:FindClosestUnitToBase()
end

--- Returns furthest unit to the platoon's squad.
-- Example: FindClosestUnit('Attack', 'Enemy', true, categories.ALLUNITS - categories.WALL).
-- @param squad Types: 'Attack', 'Artillery', 'Guard' 'None', 'Scout', 'Support'.
-- @param alliance Target alliance, types: 'Ally, 'Enemy', 'Neutral'.
-- @param canAttack true/false if the squad has to be able to attack the unit.
-- @param category Target unit category, example: categories.TECH2 .
-- @return Unit.
function CPlatoon:FindFurthestUnit(squad, alliance, canAttack, category)
end

--- TODO.
-- Needs 4 arguments
function CPlatoon:FindHighestValueUnit()
end

--- Finds prioritized unit to attack for squad.
-- Uses priorities set by SetPrioritizedTargetList function.
-- Used for TMLs to find a pick a target in their range
-- @param squad Types: 'Attack', 'Artillery', 'Guard' 'None', 'Scout', 'Support'.
-- @param alliance Target alliance, types: 'Ally, 'Enemy', 'Neutral'.
-- @param canAttack true/false if the squad has to be able to attack the unit.
-- @param position Table with position {x, y, z}.
-- @param radius Radius in game units.
-- @return Unit.
function CPlatoon:FindPrioritizedUnit(squad, alliance, canAttack, position, radius)
end

--- TODO.
-- Example: local hndl = poolPlatoon:FormPlatoon(template, personality:GetPlatoonSize(), self.Location, radius)
-- @return Formed platoon
function CPlatoon:FormPlatoon()
end

--- TODO.
function CPlatoon:GetAIPlan()
end

--- Returns army brain of the platoon.
function CPlatoon:GetBrain()
end

--- Returns number representing faction.
-- 1 UEF, 2 Aeon, 3 Cybran, 4 Seraphim.
-- @return Number 1-4
function CPlatoon:GetFactionIndex()
end

--- TODO.
function CPlatoon:GetFerryBeacons()
end

--- TODO.
function CPlatoon:GetPersonality()
end

--- TODO.
function CPlatoon:GetPlatoonLifetimeStats()
end

--- Returns platoon position
-- @return Table with position {x, y, z}.
function CPlatoon:GetPlatoonPosition()
end

--- Returns platoon unique name if it has it.
-- To return the name, it has to be set by CPlatoon:UniquelyNamePlatoon(name) function.
-- @return strName.
function CPlatoon:GetPlatoonUniqueName()
end

--- Returns list of units in theh platoon.
-- @return Table containing units.
function CPlatoon:GetPlatoonUnits()
end

--- Returns list of platoon's squad units.
-- @param squad Types: 'Attack', 'Artillery', 'Guard' 'None', 'Scout', 'Support'.
-- @return Table containing units.
function CPlatoon:GetSquadPosition(squad)
end

--- Returns units table of <squad>
-- @param squad Types: 'Attack', 'Artillery', 'Guard' 'None', 'Scout', 'Support'.
function CPlatoon:GetSquadUnits(squad)
end

--- Orders platoon to assist the target unit.
-- If squad is specified, assists the unit only with the squad.
-- @param squad Types: 'Attack', 'Artillery', 'Guard' 'None', 'Scout', 'Support'.
-- @return command
function CPlatoon:GuardTarget(target, squad)
end

--- Returns true if platoon's squad is on attack command.
-- @param squad Types: 'Attack', 'Artillery', 'Guard' 'None', 'Scout', 'Support'.
-- @return true/false
function CPlatoon:IsAttacking(squad)
end

--- Returns true if <command> is active.
-- @return true/false
function CPlatoon:IsCommandsActive(command)
end

--- Returns true if platoon's squad is on ferry command.
-- @param squad Types: 'Attack', 'Artillery', 'Guard' 'None', 'Scout', 'Support'.
-- @return true/false
function CPlatoon:IsFerrying(squad)
end

--- Returns true if platoon's squad is on move command.
-- @param squad Types: 'Attack', 'Artillery', 'Guard' 'None', 'Scout', 'Support'.
-- @return true/false
function CPlatoon:IsMoving(squad)
end

--- TODO.
-- @return true/false
function CPlatoon:IsOpponentAIRunning()
end

--- Returns true if platoon's squad is on patrol command.
-- @param squad Types: 'Attack', 'Artillery', 'Guard' 'None', 'Scout', 'Support'.
-- @return true/false
function CPlatoon:IsPatrolling(squad)
end

--- Loads <category> units into transports of the platoon.
-- @param category Unit's category to laod.
-- @return command
function CPlatoon:LoadUnits(category)
end

--- Orders platoon to move to target position.
-- If squad is specified, moves only the squad.
-- @param position Table with position {x, y, z}.
-- @param useTransports true/false
-- @param squad Types: 'Attack', 'Artillery', 'Guard' 'None', 'Scout', 'Support'.
-- @return command
function CPlatoon:MoveToLocation(position, useTransports, squad)
end

--- Orders platoon to move to target unit.
-- If squad is specified, attacks only with the squad.
-- @param target Unit to move to.
-- @param useTransports true/false
-- @param squad Types: 'Attack', 'Artillery', 'Guard' 'None', 'Scout', 'Support'.
-- @return command
function CPlatoon:MoveToTarget(target, useTransports, squad)
end

--- Orders platoon to patrol at target position.
-- If squad is specified, patrols only with the squad.
-- @param position Table with position {x, y, z}.
-- @param squad Types: 'Attack', 'Artillery', 'Guard' 'None', 'Scout', 'Support'.
-- @return command
function CPlatoon:Patrol(position, squad)
end

--- Count how many units fit the specified category.
-- @param category Unit's category. Example: categories.TECH3 .
-- @return number
function CPlatoon:PlatoonCategoryCount(category)
end

--- Count how many units fit the specified category around target position.
-- @param category Unit's category. Example: categories.TECH3 .
-- @param position Table with position {x, y, z}.
-- @return number
function CPlatoon:PlatoonCategoryCountAroundPosition(category, position, radius)
end

--- Changes platoon's formation for all squads.
-- @param formation Types: 'AttackFormation', 'GrowthFormation', 'NoFormation'.
function CPlatoon:SetPlatoonFormationOverride(formation)
end

--- Sets target priorities for platoon's squad.
-- @param squad Types: 'Attack', 'Artillery', 'Guard' 'None', 'Scout', 'Support'.
-- @param tblCategory List of categories, highest to lowerst priority, example: {categories.COMMAND, categories.EXPERIMENTAL, categories.ALLUNITS}
function CPlatoon:SetPrioritizedTargetList(squad, tblCategory)
end

--- Orders platoon to stop, cancels all commands.
-- If squad is specified, stops only the squad.
-- Cancels all commands.
-- @param squad Types: 'Attack', 'Artillery', 'Guard' 'None', 'Scout', 'Support'.
function CPlatoon:Stop(squad)
end

--- TODO.
function CPlatoon:SwitchAIPlan()
end

--- Gives a unique name to the platoon.
-- That platoon can be later returned by aiBrain:GetPlatoonUniquelyNamed(name) function
-- @param name String.
function CPlatoon:UniquelyNamePlatoon(name)
end

--- Orders platoon to drop all units at target position.
-- @param position Table with position {x, y, z}.
-- @return command
function CPlatoon:UnloadAllAtLocation(position)
end

--- Unloads specific units from transports.
-- TODO: using categories as a frist parametr doesn't break but it drops everything.
-- @param position Table with position {x, y, z}.
-- @return command
function CPlatoon:UnloadUnitsAtLocation(category, position)
end

--- TODO.
-- Example: categories.ALLUNITS, ScenarioInfo.VarTable[data.MoveBeacon]
-- @return command
function CPlatoon:UseFerryBeacon(category, beacon)
end

--- TODO.
-- Needs 1-2 parametrs, ideas: position, squad
function CPlatoon:UseTeleporter()
end

---
--
function CPlatoon:moho.platoon_methods()
end


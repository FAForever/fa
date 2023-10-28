---@meta


---@class PlatoonCommand : userdata

---@class moho.platoon_methods : InternalObject
local CPlatoon = {}

---@alias PlatoonSquadType 'Attack' | 'Artillery' | 'Guard' | 'None' | 'Scout' | 'Support'


--- Orders platoon to attack target unit.
-- If squad is specified, attacks only with the squad.
---@param target Unit Unit to attack.
---@param squad PlatoonSquadType
---@return PlatoonCommand
function CPlatoon:AttackTarget(target, squad)
end

--- Orders platoon to attack mote to target position..
-- If squad is specified, attack moves only with the squad.
---@param position Vector Table with position {x, y, z}.
---@param squad PlatoonSquadType?
---@return PlatoonCommand
function CPlatoon:AggressiveMoveToLocation(position, squad)
end

---@param threatType BrainThreatType
---@param category EntityCategory
---@return number
function CPlatoon:CalculatePlatoonThreat(threatType, category)
end

---@param threatType BrainThreatType
---@param category EntityCategory
---@param position Vector
---@param radius number
---@return number
function CPlatoon:CalculatePlatoonThreatAroundPosition(threatType, category, position, radius)
end

--- Returns true if squad can attack target unit. As an example: can this platoon attack a bomber?
---@param squad PlatoonSquadType
---@param target Unit
---@return boolean
function CPlatoon:CanAttackTarget(squad, target)
end

---@deprecated
---@return boolean
function CPlatoon:CanConsiderFormingPlatoon()
end

--- TODO.
-- Example: local formIt = poolPlatoon:CanFormPlatoon(template, personality:GetPlatoonSize(), self.Location, radius)
---@param template table
---@param size number
---@param location Vector
---@param radius number
function CPlatoon:CanFormPlatoon(template, size, location, radius)
end

--- Destroys the platoon including all its units.
function CPlatoon:Destroy()
end

--- Disband the platoon once it gets into the Idle state.
---@return PlatoonCommand
function CPlatoon:DisbandOnIdle()
end

--- Orders platoon to create ferry route to target location.
-- Can be called several times to create a non linear route.
---@param position Vector Table with position {x, y, z}.
function CPlatoon:FerryToLocation(position)
end

--- Returns closest unit to the platoon's squad.
-- Example: FindClosestUnit('Attack', 'Enemy', true, categories.ALLUNITS - categories.WALL).
---@param squad PlatoonSquadType
---@param alliance AllianceType
---@param canAttack boolean true/false if the squad has to be able to attack the unit.
---@param category EntityCategory Target unit category, example: categories.TECH2 .
---@return Unit
function CPlatoon:FindClosestUnit(squad, alliance, canAttack, category)
end

--- TODO.
-- Needs 4 parametrs.
---@deprecated
function CPlatoon:FindClosestUnitToBase()
end

--- Returns furthest unit to the platoon's squad.
-- Example: FindClosestUnit('Attack', 'Enemy', true, categories.ALLUNITS - categories.WALL).
---@param squad PlatoonSquadType
---@param alliance AllianceType
---@param canAttack boolean true/false if the squad has to be able to attack the unit.
---@param category EntityCategory Target unit category, example: categories.TECH2
---@return Unit
function CPlatoon:FindFurthestUnit(squad, alliance, canAttack, category)
end

--- TODO.
-- Needs 4 arguments
function CPlatoon:FindHighestValueUnit()
end

--- Finds prioritized unit to attack for squad.
-- Uses priorities set by SetPrioritizedTargetList function.
-- Used for TMLs to find a pick a target in their range
---@see `SetPrioritizedTargetList`
---@param squad PlatoonSquadType
---@param alliance AllianceType
---@param canAttack boolean true/false if the squad has to be able to attack the unit.
---@param position Vector Table with position {x, y, z}.
---@param radius number Radius in game units.
---@return Unit
function CPlatoon:FindPrioritizedUnit(squad, alliance, canAttack, position, radius)
end

--- TODO.
-- Example: local hndl = poolPlatoon:FormPlatoon(template, personality:GetPlatoonSize(), self.Location, radius)
-- @return Formed platoon
function CPlatoon:FormPlatoon()
end

--- TODO.
---@return string
function CPlatoon:GetAIPlan()
end

--- Returns army brain of the platoon.
---@return AIBrain
function CPlatoon:GetBrain()
end

--- Returns number representing faction.
-- 1 UEF, 2 Aeon, 3 Cybran, 4 Seraphim.
---@return number
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

--- Computes the average platoon position, returns nil if the platoon has no units
---@return Vector?
function CPlatoon:GetPlatoonPosition()
end

--- Returns platoon unique name if it has it.
-- To return the name, it has to be set by CPlatoon:UniquelyNamePlatoon(name) function.
-- @return strName.
function CPlatoon:GetPlatoonUniqueName()
end

--- Returns list of units in the platoon
---@return Unit[]
function CPlatoon:GetPlatoonUnits()
end

--- Returns list of platoon's squad units.
---@param squad PlatoonSquadType
---@return Vector
function CPlatoon:GetSquadPosition(squad)
end

--- Returns units table of <squad>
---@param squad PlatoonSquadType
---@return Unit[]
function CPlatoon:GetSquadUnits(squad)
end

--- Orders platoon to assist the target unit.
-- If squad is specified, assists the unit only with the squad.
---@param target Unit
---@param squad PlatoonSquadType
---@return PlatoonCommand
function CPlatoon:GuardTarget(target, squad)
end

--- Returns true if platoon's squad is on attack command.
---@param squad PlatoonSquadType
---@return boolean
function CPlatoon:IsAttacking(squad)
end

--- Returns true if <command> is active.
---@param command PlatoonCommand
---@return boolean
function CPlatoon:IsCommandsActive(command)
end

--- Returns true if platoon's squad is on ferry command.
---@param squad PlatoonSquadType
---@return boolean
function CPlatoon:IsFerrying(squad)
end

--- Returns true if platoon's squad is on move command.
---@param squad PlatoonSquadType
---@return boolean
function CPlatoon:IsMoving(squad)
end

--- TODO.
-- @return true/false
---@return boolean
function CPlatoon:IsOpponentAIRunning()
end

--- Returns true if platoon's squad is on patrol command.
---@param squad PlatoonSquadType
---@return boolean
function CPlatoon:IsPatrolling(squad)
end

--- Loads <category> units into transports of the platoon.
---@param category EntityCategory
---@return PlatoonCommand
function CPlatoon:LoadUnits(category)
end

--- Orders platoon to move to target position.
-- If squad is specified, moves only the squad.
---@param position Vector Table with position {x, y, z}.
---@param useTransports boolean true/false
---@param squad PlatoonSquadType?
---@return PlatoonCommand
function CPlatoon:MoveToLocation(position, useTransports, squad)
end

--- Orders platoon to move to target unit.
-- If squad is specified, move only with the squad.
---@param target Unit Unit to move to.
---@param useTransports boolean true/false
---@param squad PlatoonSquadType?
---@return PlatoonCommand
function CPlatoon:MoveToTarget(target, useTransports, squad)
end

--- Orders platoon to patrol at target position.
-- If squad is specified, patrols only with the squad.
---@param position Vector Table with position {x, y, z}.
---@param squad PlatoonSquadType
---@return PlatoonCommand
function CPlatoon:Patrol(position, squad)
end

--- Count how many units fit the specified category.
---@param category EntityCategory Unit's category. Example: categories.TECH3 .
---@return number
function CPlatoon:PlatoonCategoryCount(category)
end

--- Count how many units fit the specified category around target position.
---@param category EntityCategory Unit's category. Example: categories.TECH3 .
---@param position Vector Table with position {x, y, z}.
---@param radius number
---@return number
function CPlatoon:PlatoonCategoryCountAroundPosition(category, position, radius)
end

--- Changes platoon's formation for all squads.
---@param formation string Types: 'AttackFormation', 'GrowthFormation', 'NoFormation'.
function CPlatoon:SetPlatoonFormationOverride(formation)
end

--- Sets target priorities for platoon's squad.
---@param squad PlatoonSquadType
---@param tblCategory EntityCategory[] List of categories, highest to lowerst priority, example: {categories.COMMAND, categories.EXPERIMENTAL, categories.ALLUNITS}
function CPlatoon:SetPrioritizedTargetList(squad, tblCategory)
end

--- Orders platoon to stop, cancels all commands.
-- If squad is specified, stops only the squad.
-- Cancels all commands.
---@param squad PlatoonSquadType?
function CPlatoon:Stop(squad)
end

--- TODO.
function CPlatoon:SwitchAIPlan()
end

--- Gives a unique name to the platoon.
-- That platoon can be later returned by aiBrain:GetPlatoonUniquelyNamed(name) function
---@param name string String.
function CPlatoon:UniquelyNamePlatoon(name)
end

--- Orders platoon to drop all units at target position.
---@param position Vector Table with position {x, y, z}.
---@return PlatoonCommand
function CPlatoon:UnloadAllAtLocation(position)
end

--- Unloads specific units from transports (carriers).
-- This seems to work only with carriers and not with air transports.
---@param category EntityCategory Unit category (categories.BOMBER).
---@param position Vector Table with position {x, y, z}.
---@return PlatoonCommand
function CPlatoon:UnloadUnitsAtLocation(category, position)
end

--- TODO.
---@param category EntityCategory categories.ALLUNITS, ScenarioInfo.VarTable[data.MoveBeacon]
---@param beacon any
---@return PlatoonCommand
function CPlatoon:UseFerryBeacon(category, beacon)
end

--- TODO.
---@param gameObject any TODO.
---@param squad PlatoonSquadType
function CPlatoon:UseTeleporter(gameObject, squad)
end

return CPlatoon

---@meta


---@class PlatoonCommand : userdata
---@see moho.platoon_methods.IsCommandsActive

---Platoon is automatically destoryed when all it's units die.
---@class moho.platoon_methods : InternalObject
local CPlatoon = {}

---@alias PlatoonSquadType 'Attack' | 'Artillery' | 'Guard' | 'None' | 'Scout' | 'Support' | 'Unassigned'


--- Orders platoon to attack target unit.
-- If squad is specified, attacks only with the squad.
---@param target Unit Unit to attack.
---@param squad? PlatoonSquadType
---@return PlatoonCommand
function CPlatoon:AttackTarget(target, squad)
end

--- Orders platoon to attack move to target position..
-- If squad is specified, attack moves only with the squad.
---@param position Vector Table with position {x, y, z}.
---@param squad? PlatoonSquadType
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
---@param template PlatoonTemplate
---@param unknown2 string
---@return boolean
function CPlatoon:CanConsiderFormingPlatoon(template, unknown2)
end

--- TODO.
-- Example: local formIt = poolPlatoon:CanFormPlatoon(template, personality:GetPlatoonSize(), self.Location, radius)
---@param template PlatoonTemplate The template table for the faction, see platoontemplates for more details.
---@param multiplier integer Multiplies the squad max size in the template by this number.
---@param location? Vector The position vector to search for units from.
---@param radius? number The radius to search for units.
---@return boolean
function CPlatoon:CanFormPlatoon(template, multiplier, location, radius)
end

---Destroys the platoon and it's units, if no `squad` is specified
---
---In both cases, the units are destroyed after they complete their orders.
---@see moho.aibrain_methods.DisbandPlatoon For removing the platoon without destroying it's units.
---@param squad? PlatoonSquadType If specified only the squad units are destroyed. The platoon itself is **NOT** destroyed.
function CPlatoon:Destroy(squad)
end

---Disband the platoon once all the squads finish their commands.
function CPlatoon:DisbandOnIdle()
end

---Orders platoon to create ferry route to target location.
---Can be called several times to create a non linear route.
---
---The first position creates a Beacon unit.
---@param position Vector
---@return PlatoonCommand
function CPlatoon:FerryToLocation(position)
end

---Returns closest unit to the platoon's squad.
---
---Based on intel.
---@param squad PlatoonSquadType
---@param alliance AllianceType
---@param canAttack boolean true/false if the squad has to be able to attack the unit.
---@param category EntityCategory Target unit category, example: categories.TECH2 .
---@return Unit?
function CPlatoon:FindClosestUnit(squad, alliance, canAttack, category)
end

---Finds closest unit to platoon's army structures.
---
---Based on intel.
---@param squad PlatoonSquadType
---@param alliance AllianceType
---@param canAttack boolean
---@param category EntityCategory Target unit category filter.
---@return Unit?
function CPlatoon:FindClosestUnitToBase(squad, alliance, canAttack, category)
end

--- Returns furthest unit to the platoon's squad.
---
---Based on intel.
---@param squad PlatoonSquadType
---@param alliance AllianceType
---@param canAttack boolean true/false if the squad has to be able to attack the unit.
---@param category EntityCategory Target unit category, example: categories.TECH2
---@return Unit?
function CPlatoon:FindFurthestUnit(squad, alliance, canAttack, category)
end

---Based on intel.
---@param squad PlatoonSquadType
---@param alliance AllianceType
---@param canAttack boolean true/false if the squad has to be able to attack the unit.
---@param category EntityCategory Target unit category, example: categories.TECH2
---@return Unit?
function CPlatoon:FindHighestValueUnit(squad, alliance, canAttack, category)
end

---Finds prioritized unit to attack for squad.
---Uses priorities set by SetPrioritizedTargetList function.
---Used for TMLs to find a pick a target in their range
---
---Based on intel.
---@see moho.platoon_methods.SetPrioritizedTargetList
---@param squad PlatoonSquadType
---@param alliance AllianceType
---@param canAttack boolean true/false if the squad has to be able to attack the unit.
---@param position Vector Table with position {x, y, z}.
---@param radius number Radius in game units.
---@return Unit?
function CPlatoon:FindPrioritizedUnit(squad, alliance, canAttack, position, radius)
end

--- TODO.
-- Example: local hndl = poolPlatoon:FormPlatoon(template, personality:GetPlatoonSize(), self.Location, radius)
---@param template table The template table for the faction, see platoontemplates for more details.
---@param multiplier number Multiplies the squad max size in the template by this number.
---@param position? Vector The position vector to search for units from.
---@param radius? number The radius to search for units.
---@return Platoon
function CPlatoon:FormPlatoon(template, multiplier, position, radius)
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
---@return integer
function CPlatoon:GetFactionIndex()
end

---Returns a list of beacons this platoon created.
---
---@see moho.platoon_methods.UseFerryBeacon
---@return TransportBeaconUnit[]
function CPlatoon:GetFerryBeacons()
end

--- TODO.
---@return AIPersonality
function CPlatoon:GetPersonality()
end

--- TODO.
---@return number
function CPlatoon:GetPlatoonLifetimeStats()
end

--- Computes the average platoon position, returns nil if the platoon has no units
---@return Vector?
function CPlatoon:GetPlatoonPosition()
end

---Returns platoon's unique name if it has it.
---
---@see moho.platoon_methods.UniquelyNamePlatoon To set the name
---@see moho.aibrain_methods.GetPlatoonUniquelyNamed To get the platoon by the unique name.
---@return string uniqueName Defaults to empty string
function CPlatoon:GetPlatoonUniqueName()
end

--- Returns list of units in the platoon
---@return Unit[]
function CPlatoon:GetPlatoonUnits()
end

---Returns an average position of `squad` units.
---@param squad PlatoonSquadType
---@return Vector? `nil` when the squad has no units.
function CPlatoon:GetSquadPosition(squad)
end

---Returns a list of `squad` units
---@param squad PlatoonSquadType
---@return Unit[]? `nil` when the squad has no units.
function CPlatoon:GetSquadUnits(squad)
end

--- Orders platoon to assist the target unit.
-- If squad is specified, assists the unit only with the squad.
---@param target Unit
---@param squad? PlatoonSquadType
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
---@return boolean
function CPlatoon:IsOpponentAIRunning()
end

---Returns true if platoon's squad is on patrol command.
---
---@see moho.platoon_methods.Patrol
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
---If squad is specified, moves only the squad.
---
---@see moho.platoon_methods.IsMoving
---@param position Vector Table with position {x, y, z}.
---@param useTransports boolean
---@param squad PlatoonSquadType?
---@return PlatoonCommand
function CPlatoon:MoveToLocation(position, useTransports, squad)
end

--- Orders platoon to move to target unit.
--- If squad is specified, move only with the squad.
---
---@see moho.platoon_methods.IsMoving
---@param target Unit Unit to move to.
---@param useTransports boolean
---@param squad PlatoonSquadType?
---@return PlatoonCommand
function CPlatoon:MoveToTarget(target, useTransports, squad)
end

---Orders platoon to patrol at target position.
---
---If squad is specified, patrols only with the squad.
---
---@see moho.platoon_methods.IsPatrolling
---@param position Vector Table with position {x, y, z}.
---@param squad? PlatoonSquadType
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
---@param formation UnitFormations
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
---@param plan string
---@return string
function CPlatoon:SwitchAIPlan(plan)
end

---Gives a unique name to the platoon.
---
---@see moho.platoon_methods.GetPlatoonUniqueName to get the name of the platoon.
---@see moho.aibrain_methods.GetPlatoonUniquelyNamed To get the platoon by the unique name.
---@param name string
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

---Orders the units to use the ferry beacon
---
---@see moho.platoon_methods.GetFerryBeacons To get list of available beacons to use.
---@param category EntityCategory
---@param beacon TransportBeaconUnit
---@return PlatoonCommand
function CPlatoon:UseFerryBeacon(category, beacon)
end

--- TODO.
---@param gameObject any TODO.
---@param squad PlatoonSquadType
function CPlatoon:UseTeleporter(gameObject, squad)
end

return CPlatoon

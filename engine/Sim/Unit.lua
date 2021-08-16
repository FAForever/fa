--- Class Unit
-- @classmod Sim.Unit

--- Add a command cap to a unit.
-- Also adds a button to the UI, or enables it, for the unit to use the new command.
-- @param capName String Available:
-- RULEUCC_Move
-- RULEUCC_Stop
-- RULEUCC_Attack
-- RULEUCC_Guard
-- RULEUCC_Patrol
-- RULEUCC_RetaliateToggle
-- RULEUCC_Repair
-- RULEUCC_Capture
-- RULEUCC_Transport
-- RULEUCC_CallTransport
-- RULEUCC_Nuke
-- RULEUCC_Tactical
-- RULEUCC_Teleport
-- RULEUCC_Ferry
-- RULEUCC_SiloBuildTactical
-- RULEUCC_SiloBuildNuke
-- RULEUCC_Sacrifice
-- RULEUCC_Pause
-- RULEUCC_Overcharge
-- RULEUCC_Dive
-- RULEUCC_Reclaim
-- RULEUCC_SpecialAction
-- RULEUCC_Dock
-- RULEUCC_Script
-- RULEUCC_Invalid
function Unit:AddCommandCap(capName)
end

--- Add a toggle cap to a unit.
-- Also adds a button to the UI, or enables it, for the unit to use the new command.
-- @param capName String Available:
-- RULEUTC_ShieldToggle
-- RULEUTC_WeaponToggle
-- RULEUTC_JammingToggle
-- RULEUTC_IntelToggle
-- RULEUTC_ProductionToggle
-- RULEUTC_StealthToggle
-- RULEUTC_GenericToggle
-- RULEUTC_SpecialToggle
-- RULEUTC_CloakToggle
function Unit:AddToggleCap(capName)
end

--- Adds unit to the storage of the carrier.
-- @param unit Target unit to load.
function Unit:AddUnitToStorage(unit)
end

--- Changes the unit's armor type.
-- @param damageTypeName String, see lua/armordefinition.lua available types.
-- @param multiplier TODO.
function Unit:AlterArmor(damageTypeName, multiplier)
end

--- Calculate the desired world position from the supplied relative vector from the center of the unit.
-- Used for naval factories to set rally point under them.
-- @param vector Table {x, y, z}.
function Unit:CalculateWorldPositionFromRelative(vector)
end

--- See if the unit can build the target unit.
-- @param bpID Blueprint ID of the target unit, example 'ueb0101'.
-- @return true/false.
function Unit:CanBuild(bpID)
end

--- See if the unit can path to the goal.
-- @param position Table with position {x, y, z}.
-- @return result, bestGoal true/false, if falses, returns the closest position, else the original position.
function Unit:CanPathTo(position)
end

--- See if the unit can path to the goal rectangle.
-- TODO: find out if it returns position as well
-- @param rectangle Map area created by function Rect(x0, z0, x1, z1).
-- @return true/false
function Unit:CanPathToRect(rectangle)
end

--- TODO.
function Unit:ClearFocusEntity()
end

--- TODO.
function Unit:EnableManipulators([string boneName | int boneIndex],  bool Enable)
end

--- TODO.
function Unit:GetArmorMult(damageTypeName)
end

--- Get the tactical attack manager object of this unit.
function Unit:GetAttacker()
end

--- Returns a blip (if any) that the given army has for the unit
-- @return blip
function Unit:GetBlip(armyIndex)
end

--- Returns the build rate of a unit.
-- What fraction of target unit it builds per second.
-- @return rate
function Unit:GetBuildRate()
end

--- Returns list of unit that the unit is transporting.
-- @return Table List of units or empty table.
function Unit:GetCargo()
end

--- Return table of commands queued up for this unit.
-- @return table
function Unit:GetCommandQueue()
end

--- Get the consumption of energy of the unit.
-- @return number
function Unit:GetConsumptionPerSecondEnergy()
end

--- Get the consumption of mass of the unit.
-- @return number
function Unit:GetConsumptionPerSecondMass()
end

--- Return the name of the layer the unit is currently in. This value is cached inside
-- unit.Layer each time a layer changes (when OnLayerChanged is called).
-- @return layer String, name of the layer, types: 'Air','Land', 'Orbital', 'Seabed', 'Sub', 'Water'.
function Unit:GetCurrentLayer()
end

--- Returns the current move location of the unit.
-- TODO: untested.
-- @return position Table with position {x, y ,z}.
function Unit:GetCurrentMoveLocation()
end

--- Get the fire state for the unit.
-- TODO find out return format.
function Unit:GetFireState()
end

--- TODO.
function Unit:GetFocusUnit(self)
end

--- Find out ratio of fuel ramaining.
-- @return ratio How much fuel left, range 0 - 1.
function Unit:GetFuelRatio()
end

--- Get the fuel use time.
-- @return number Fuel left in seconds.
function Unit:GetFuelUseTime()
end

--- Returns the unit that is being guarded.
-- @return unit Guarded unit or nil.
function Unit:GetGuardedUnit()
end

--- Find out units that are guarding this unit.
-- @return table Table of units that are guarding this uni.
function Unit:GetGuards()
end

--- Find out current health
-- @return number HP remaining.
function Unit:GetHealth()
end

--- Get the navigator object of this unit.
function Unit:GetNavigator()
end

--- Find out number of nuclear missile this unit has available.
-- @return number
function Unit:GetNukeSiloAmmoCount()
end

--- Get number of factory/engineer build orders that fit in the specified category.
-- @param category Unit's category, example: categories.ALLUNITS.
function Unit:GetNumBuildOrders(category)
end

--- Get the production of energy of the unit.
-- @return number Production of energy per second.
function Unit:GetProductionPerSecondEnergy()
end

--- Get the production of mass of the unit.
-- @return number Production of mass per second.
function Unit:GetProductionPerSecondMass()
end

--- Get the rally point for the factory.
-- @return position Table with position {x, y ,z}.
function Unit:GetRallyPoint()
end

--- Return the fraction of requested resources this unit consumed last tick.
-- Normally 1, but can be fractional if economy is struggling.
function Unit:GetResourceConsumed()
end

--- Get the current toggle state of the script bit that matches the string.
-- TODO.
function Unit:GetScriptBit()
end

--- Get the shield ratio.
-- @return float Range 0 - 1.
function Unit:GetShieldRatio()
end

--- Find out unit's specific statistics.
-- Example: 'KILLS'.
-- @param statName String, name of the stat to find out.
-- @param [defaultVal] TODO.
-- Special case for the Salem:
--   GetStat("h1_SetSalemAmph", 0 or 1) 
--   Disable/Enable amphibious mode
function Unit:GetStat(statName, [defaultVal])
end

--- Find out number of tactical missile this unit has available.
-- @return number
function Unit:GetTacticalSiloAmmoCount()
end

--- Return our target unit if we have one.
-- @return entity or nil.
function Unit:GetTargetEntity()
end

---
--  Unit:GetTransportFerryBeacon()
function Unit:GetTransportFerryBeacon()
end

--- Returns the unit's blueprint ID.
-- @return bpID
function Unit:GetUnitId(self)
end

--- TODO.
--  GetVelocity() -> x,y,z
function Unit:GetVelocity()
end

--- return the index'th weapon of this unit.
-- Index must be between 1 and self:GetWeaponCount(), inclusive.
-- @return weapon
function Unit:GetWeapon(index)
end

--- Return the number of weapons on this unit.
-- Note that dummy weapons are not included in the count, so this may differ from the number of weapons defined in the unit's blueprint.
-- @return number
function Unit:GetWeaponCount()
end

--- TODO.
function Unit:GetWorkProgress()
end

--- Give nuclear missile to the unit.
-- @param num Amout of missiles to give.
function Unit:GiveNukeSiloAmmo(num)
end

--- Give tactical missile to the unit.
-- @param num Amout of missiles to give.
function Unit:GiveTacticalSiloAmmo(num)
end

--- TODO.
function Unit:HasMeleeSpaceAroundTarget(target)
end

--- TODO.
function Unit:HasValidTeleportDest()
end

--- Makes unit's bone invisible.
-- @param bone Bone name or index.
-- @param affectChildren true/false.
function Unit:HideBone(bone, affectChildren)
end

--- See if unit is under construction.
-- @return bool true/false.
function Unit:IsBeingBuilt()
end

--- Returns if this unit can be captured or not.
-- @return bool true/false.
function Unit:IsCapturable()
end

--- See if the eunit is in Idle state or not.
-- @return bool true/false.
function Unit:IsIdleState()
end

--- See if it's a mobile unit.
-- @return bool true/false.
function Unit:IsMobile()
end

--- See if the unit is moving or not.
-- @return bool true/false.
function Unit:IsMoving()
end

--- See if the unit has paused overcharge.
-- @return bool true/false.
function Unit:IsOverchargePaused()
end

--- See if the unit is paused.
-- @return bool true/false.
function Unit:IsPaused()
end

--- See if the unit is stunned.
-- @return bool true/false.
function Unit:IsStunned()
end

--- See if the unit is in given state.
-- @param stateName String, see SetUnitState function for available states.
-- @return bool true/false.
function Unit:IsUnitState(stateName)
end

--- TODO.
-- @return bool true/false.
function Unit:IsValidTarget(self)
end

--- Kill a specific manipulator held by a script object.
-- TODO: param
function Unit:KillManipulator()
end

--- TODO.
function Unit:KillManipulators([boneName|boneIndex])
end

--- TODO.
function Unit:MeleeWarpAdjacentToTarget(target)
end

--- TODO.
function Unit:PrintCommandQueue()
end

--- TODO.
function Unit:RecoilImpulse(x, y, z)
end

--- Allow building of categories for this unit.
-- @param category Unit's category, example categories.TECH1.
function Unit:RemoveBuildRestriction(category)
end

--- Remove a command cap to a unit.
-- Also removes the command button, or disables it, from the UI, see AddCommandCap for available options. 
-- @param capName String.
function Unit:RemoveCommandCap(capName)
end

--- Remove amout of nuke missiles from the unit. 
-- @param num Amount of nukes to remove.
function Unit:RemoveNukeSiloAmmo(num)
end

--- Remove amout of tactical missiles from the unit. 
-- @param num Amount of tactical missiles to remove.
function Unit:RemoveTacticalSiloAmmo(num)
end

--- Remove a toggle cap to a unit.
-- Also removes the command button, or disables it, from the UI, see AddToggleCap for available options. 
-- @param capName String.
function Unit:RemoveToggleCap(capName)
end

--- Restore buildable categories to that as defined in the blueprint
function Unit:RestoreBuildRestrictions()
end

--- Restore the command caps of the unit back to blueprint spec.
function Unit:RestoreCommandCaps()
end

--- Restore the toggle caps of the unit back to blueprint spec.
function Unit:RestoreToggleCaps()
end

--- Revert the collision shape to the blueprint spec.
function Unit:RevertCollisionShape()
end

--- Revert the elevation of the unit back to the blueperint spec.
function Unit:RevertElevation()
end

--- Restore regen rate of the unit back to blueprint spec.
function Unit:RevertRegenRate()
end

--- TODO.
--  ScaleGetBuiltEmitter(self, emitter)
function Unit:ScaleGetBuiltEmitter(self, emitter)
end

--- Set the acceleration multiplier of the unit.
-- @param float Multiplier to apply.
function Unit:SetAccMult(float)
end

--- Set auto silo build mode to on/off.
-- @param bool true/false
function Unit:SetAutoMode(bool)
end

--- TODO.
-- @param flag true/false.
function Unit:SetBlockCommandQueue(flag)
end

--- Set the break off distance multiplier of the unit.
-- @param float Multiplier to apply.
function Unit:SetBreakOffDistanceMult(float)
end

--- Set the break off trigger multiplier of the unit.
-- TODO: find out what this does.
function Unit:SetBreakOffTriggerMult(float)
end

--- Set the build rate of a unit: what fraction of target unit it builds per second.
-- @param frac Number.
function Unit:SetBuildRate(frac)
end

--- TODO.
-- @param flag true/false.
function Unit:SetBusy(flag)
end

--- Set if this unit can be captured or not.
-- @param flag true/false.
function Unit:SetCapturable(flag)
end

--- TODO.
-- @param flag true/false.
function Unit:SetConsumptionActive(flag)
end

--- Set the consumption of energy of a unit.
-- @param value Amount of energy consumed per second.
function Unit:SetConsumptionPerSecondEnergy(value)
end

--- Set the consumption of mass of the unit.
-- @param value Amount of mass consumed per second.
function Unit:SetConsumptionPerSecondMass(value)
end

--- Set the creator for this unit.
-- Used for example for UEF ACU pods or Kennel pods.
-- @param unit Parent unit.
function Unit:SetCreator(unit)
end

--- Sets a custom name for the unit, displayed by green text.
-- @param name String with the name.
function Unit:SetCustomName(name)
end

--- If set true, enemy units won't target this unit.
-- Accidental hits can still damage it but it enemy units won't lock on it.
-- @param flag true/false.
function Unit:SetDoNotTarget(flag)
end

--- Set the elevation of the unit
-- @param TODO.
function Unit:SetElevation()
end

--- Set a specific fire state for the retaliation state of the unit.
-- @param fireState Return fie - 0, Hold fire - 1 and Ground fire - 2.
function Unit:SetFireState(fireState)
end

--- TODO.
function Unit:SetFocusEntity(focus)
end

--- Set the fuel ratio.
-- How much fuel has the unit left
-- @param ratio Float, range 0 - 1.
function Unit:SetFuelRatio(ratio)
end

--- Set the fuel use time.
-- @seconds Number, how many seconds of can the unit fly.
function Unit:SetFuelUseTime(seconds)
end

--- Sets if the unit is able to move.
-- @param flag true/false.
function Unit:SetImmobile(flag)
end

---
--  SetIsValidTarget(self,bool)
function Unit:SetIsValidTarget(self, bool)
end

--- Set if this unit has an overcharge pasued.
-- @param flag true/false.
function Unit:SetOverchargePaused(flag)
end

--- Pauses building, upgrading and other tasks of the unit.
-- @param flag true/false.
function Unit:SetPaused(flag)
end

--- Enable, disable production of resources on the unit.
-- Used for mass fabricators or extractors for example.
-- @param flag true/false.
function Unit:SetProductionActive(flag)
end

--- Set the production of energy of the unit.
-- @param number Amout of energy to produce per second.
function Unit:SetProductionPerSecondEnergy(number)
end

--- Set the production of mass of the unit.
-- @param number Amout of mass to produce per second.
function Unit:SetProductionPerSecondMass(number)
end

--- Set if this unit can be reclaimed or not.
-- @param flag true/false.
function Unit:SetReclaimable(flag)
end

--- Set the regen rate of a unit.
-- @param rate Number of HPs regenerated per second.
function Unit:SetRegenRate(rate)
end

--- Set the script bit that matches the string to the desired state.
-- @param string TODO.
-- @param state true/false.
function Unit:SetScriptBit(string, state)
end

--- Set the shield ratio.
-- @param ratio Float, range 0 - 1.
function Unit:SetShieldRatio(ratio)
end

--- Set the speed multiplier of the unit.
-- @param float Multiplier to apply.
function Unit:SetSpeedMult(float)
end

--- Set the unit statistic.
-- @param name String, name of the stat to set.
-- @param value Number.
function Unit:SetStat(name, value)
end

--- Sets the icon underlay to set texture.
-- Used in campaign to highlight objetcive targets. Example 'icon_objective_primary', the dds textures must be in textures\ui\common\game\strategicicons.
-- @param icon String, name of the texture to apply, '' - empty string to reset.
function Unit:SetStrategicUnderlay(icon)
end

--- Stuns the unit for the set time.
-- @param time Number, seconds.
function Unit:SetStunned(time)
end

--- Set the turn multiplier of the unit.
-- @param float Multiplier to apply.
function Unit:SetTurnMult(float)
end

--- Set if the unit can be selected.
-- @param flag true/false.
function Unit:SetUnSelectable(flag)
end

--- Set unit's state.
-- @param stateName String, name of the state to set.
-- 'Immobile'
-- 'Moving'
-- 'Attacking'
-- 'Guarding'
-- 'Building'
-- 'Upgrading'
-- 'WaitingForTransport'
-- 'TransportLoading'
-- 'TransportUnloading'
-- 'MovingDown'
-- 'MovingUp'
-- 'Patrolling'
-- 'Busy'
-- 'Attached'
-- 'BeingReclaimed'
-- 'Repairing'
-- 'Diving'
-- 'Surfacing'
-- 'Teleporting'
-- 'Ferrying'
-- 'WaitForFerry'
-- 'AssistMoving'
-- 'PathFinding'
-- 'ProblemGettingToGoal'
-- 'NeedToTerminateTask'
-- 'Capturing'
-- 'BeingCaptured'
-- 'Reclaiming'
-- 'AssistingCommander'
-- 'Refueling'
-- 'GuardBusy'
-- 'ForceSpeedThrough'
-- 'UnSelectable'
-- 'DoNotTarget'
-- 'LandingOnPlatform'
-- 'CannotFindPlaceToLand'
-- 'BeingUpgraded'
-- 'Enhancing'
-- 'BeingBuilt'
-- 'NoReclaim'
-- 'NoCost'
-- 'BlockCommandQueue'
-- 'MakingAttackRun'
-- 'HoldingPattern'
-- 'SiloBuildingAmmo'
-- @param bool true/false.
function Unit:SetUnitState(stateName, bool)
end

--- Set the work progress on the unit.
-- Used for ACU upgrades, missile construction? TODO.
-- @param float Range 0 - 1, where 1 is completed.
function Unit:SetWorkProgress(float)
end

--- Makes unit's bone visible.
-- @param bone Bone name or index.
-- @param affectChildren true/false.
function Unit:ShowBone(bone, affectChildren)
end

--- Stops production of a missile.
function Unit:StopSiloBuild()
end

--- Test if a unit has this specified set to true in the blueprint spec.
-- @param capName String.
function Unit:TestCommandCaps(capName)
end

--- Test if a unit has this specified set to true in the blueprint spec.
-- @param capName String.
function Unit:TestToggleCaps(capName)
end

--- Toggle the fire state for the retaliation state of the unit.
function Unit:ToggleFireState()
end

--- Toggle the script bit that matches the string.
-- TODO.
function Unit:ToggleScriptBit()
end

--- Detach all units from a transport.
-- @param destroySomeUnits TODO.
function Unit:TransportDetachAllUnits(destroySomeUnits)
end

--- Find out if carrier is full or not.
-- @return true/false.
function Unit:TransportHasAvailableStorage()
end

--- Find out if the target unit can fit into the carrier.
-- @param target Unit to test.
-- @return true/false.
function Unit:TransportHasSpaceFor(target)
end

---
--  derived from Entity
function Unit:base()
end

---
--
function Unit:moho.unit_methods()
end


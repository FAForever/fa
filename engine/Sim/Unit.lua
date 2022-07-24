---@declare-global
---@class moho.unit_methods : moho.entity_methods
local Unit = {}

---@class UnitId: string

---@alias CommandCap
---| "RULEUCC_Move"
---| "RULEUCC_Stop"
---| "RULEUCC_Attack"
---| "RULEUCC_Guard"
---| "RULEUCC_Patrol"
---| "RULEUCC_RetaliateToggle"
---| "RULEUCC_Repair"
---| "RULEUCC_Capture"
---| "RULEUCC_Transport"
---| "RULEUCC_CallTransport"
---| "RULEUCC_Nuke"
---| "RULEUCC_Tactical"
---| "RULEUCC_Teleport"
---| "RULEUCC_Ferry"
---| "RULEUCC_SiloBuildTactical"
---| "RULEUCC_SiloBuildNuke"
---| "RULEUCC_Sacrifice"
---| "RULEUCC_Pause"
---| "RULEUCC_Overcharge"
---| "RULEUCC_Dive"
---| "RULEUCC_Reclaim"
---| "RULEUCC_SpecialAction"
---| "RULEUCC_Dock"
---| "RULEUCC_Script"
---| "RULEUCC_Invalid"

---@alias ToggleCap
---| "RULEUTC_ShieldToggle"
---| "RULEUTC_WeaponToggle"
---| "RULEUTC_JammingToggle"
---| "RULEUTC_IntelToggle"
---| "RULEUTC_ProductionToggle"
---| "RULEUTC_StealthToggle"
---| "RULEUTC_GenericToggle"
---| "RULEUTC_SpecialToggle"
---| "RULEUTC_CloakToggle"

---@alias UnitState
---| "Immobile"
---| "Moving"
---| "Attacking"
---| "Guarding"
---| "Building"
---| "Upgrading"
---| "WaitingForTransport"
---| "TransportLoading"
---| "TransportUnloading"
---| "MovingDown"
---| "MovingUp"
---| "Patrolling"
---| "Busy"
---| "Attached"
---| "BeingReclaimed"
---| "Repairing"
---| "Diving"
---| "Surfacing"
---| "Teleporting"
---| "Ferrying"
---| "WaitForFerry"
---| "AssistMoving"
---| "PathFinding"
---| "ProblemGettingToGoal"
---| "NeedToTerminateTask"
---| "Capturing"
---| "BeingCaptured"
---| "Reclaiming"
---| "AssistingCommander"
---| "Refueling"
---| "GuardBusy"
---| "ForceSpeedThrough"
---| "UnSelectable"
---| "DoNotTarget"
---| "LandingOnPlatform"
---| "CannotFindPlaceToLand"
---| "BeingUpgraded"
---| "Enhancing"
---| "BeingBuilt"
---| "NoReclaim"
---| "NoCost"
---| "BlockCommandQueue"
---| "MakingAttackRun"
---| "HoldingPattern"
---| "SiloBuildingAmmo"

---@alias LayerName "Air" | "Land" | "Orbital" | "Seabed" | "Sub" | "Water"

---
---@param category moho.EntityCategory
function Unit:AddBuildRestriction(category)
end

--- Also adds a button to the UI, or enables it, for the unit to use the new command.
---@param capName CommandCap
function Unit:AddCommandCap(capName)
end

--- Adds a toggle cap to the unit.
--- Also adds a button to the UI, or enables it, for the unit to use the new command.
---@param capName ToggleCap
function Unit:AddToggleCap(capName)
end

--- Adds unit to the storage of the carrier
---@param unit Unit
function Unit:AddUnitToStorage(unit)
end

--- Changes the unit's multiplier to a damage type
---@param damageTypeName DamageType
---@param multiplier number
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

--- See if the unit can path to the goal
---@param position Position
---@return boolean result if false, returns the closest position, else the original position
---@return Position bestGoal
function Unit:CanPathTo(position)
end

--- See if the unit can path to the goal rectangle
--- TODO: find out if it returns position as well
---@param rectangle Rectangle
---@return boolean
function Unit:CanPathToRect(rectangle)
end

--- TODO.
function Unit:ClearFocusEntity()
end

--- TODO.
---@param bone string|number boneName or boneIndex
---@param Enable boolean
function Unit:EnableManipulators(bone, Enable)
end

--- Gets the unit's multiplier to a damage type
---@param damageTypeName DamageType
---@return number
function Unit:GetArmorMult(damageTypeName)
end

--- Get the tactical attack manager object of this unit
---@return AttackManager
function Unit:GetAttacker()
end

--- Returns a blip (if any) that the given army has for the unit
---@param army Army
---@return Blip
function Unit:GetBlip(army)
end

---
---@return UnitBlueprint
function Unit:GetBlueprint()
end

---@return UnitBlueprint
function Unit:GetBlueprint()
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

--- Returns table of commands queued up for this unit
---@return OrderInfo[]
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
--- `Unit.Layer` each time the layer changes (when `OnLayerChanged` is called) and the hierarchy
--- is called accordingly (e.g. ends up in `Unit.OnLayerChange`).
---@return LayerName
function Unit:GetCurrentLayer()
end

--- Returns the current move location of the unit.
-- TODO: untested.
-- @return position Table with position {x, y ,z}.
function Unit:GetCurrentMoveLocation()
end

--- Get the fire state for the unit
---@return FireState
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

--- Returns the unit that is being guarded
---@return Unit | nil
function Unit:GetGuardedUnit()
end

--- Find out units that are guarding this unit
---@return Unit[]
function Unit:GetGuards()
end

--- Find out current health
---@return number
function Unit:GetHealth()
end

--- Get the navigator object of this unit.
function Unit:GetNavigator()
end

--- Find out number of nuclear missile this unit has available
---@return number
function Unit:GetNukeSiloAmmoCount()
end

--- Get number of factory/engineer build orders that fit in the specified category
---@param category EntityCategory
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

--- Get the current toggle state of the script bit that matches the number
---@param bit number
---@return boolean
function Unit:GetScriptBit(bit)
end

--- Get the shield ratio, `0.0` - `1.0`
---@return number
function Unit:GetShieldRatio()
end

--- Find out unit's specific statistics.
-- Example: 'KILLS'.
---@param statName string, name of the stat to find out.
---@param defaultVal? number TODO.
---@return number
-- Special case for the Salem:
--   GetStat("h1_SetSalemAmph", 0 or 1) 
--   Disable/Enable amphibious mode
function Unit:GetStat(statName, defaultVal)
end

--- Find out number of tactical missile this unit has available
---@return number
function Unit:GetTacticalSiloAmmoCount()
end

--- Return our target unit if we have one
---@return Entity | Unit | nil
function Unit:GetTargetEntity()
end

---
--  Unit:GetTransportFerryBeacon()
function Unit:GetTransportFerryBeacon()
end

--- Returns the unit's blueprint ID.
---@return UnitId bpID
function Unit:GetUnitId(self)
end

--- TODO.
--  GetVelocity() -> x,y,z
function Unit:GetVelocity()
end

--- Return the index'th weapon of this unit.
--- Index must be between `1` and `GetWeaponCount()`, inclusive.
---@return Weapon
function Unit:GetWeapon(index)
end

--- Return the number of weapons on this unit.
--- Note that dummy weapons are not included in the count, so this may differ from
--- the number of weapons defined in the unit's blueprint.
---@return number
function Unit:GetWeaponCount()
end

--- TODO.
function Unit:GetWorkProgress()
end

--- Give nuclear missile to the unit
---@param amount number
function Unit:GiveNukeSiloAmmo(amount)
end

--- Give tactical missile to the unit
---@param amount number
function Unit:GiveTacticalSiloAmmo(amount)
end

---
---@param target Entity | Unit
---@return boolean
function Unit:HasMeleeSpaceAroundTarget(target)
end

---
---@return boolean
function Unit:HasValidTeleportDest()
end

--- Makes unit's bone invisible.
-- @param bone Bone name or index.
-- @param affectChildren true/false.
function Unit:HideBone(bone, affectChildren)
end

--- Returns if the unit is under construction
---@return boolean
function Unit:IsBeingBuilt()
end

--- Returns if the unit can be captured
---@return boolean
function Unit:IsCapturable()
end

--- Returns if the unit is in an Idle state
---@return boolean
function Unit:IsIdleState()
end

--- Returns if it's a mobile unit
---@return boolean
function Unit:IsMobile()
end

--- Returns if the unit is moving
---@return boolean
function Unit:IsMoving()
end

--- Returns if the unit has paused overcharge
---@return boolean
function Unit:IsOverchargePaused()
end

--- Returns if the unit is paused
---@return boolean
function Unit:IsPaused()
end

--- Returns if the unit is stunned
---@return boolean
function Unit:IsStunned()
end

--- Returns if the unit is in given state
---@param stateName UnitState
---@return boolean
function Unit:IsUnitState(stateName)
end

---
---@return boolean
function Unit:IsValidTarget()
end

--- Kill a specific manipulator held by a script object.
-- TODO: param
function Unit:KillManipulator()
end

--- TODO.
---@param bone string|number boneName|boneIndex
function Unit:KillManipulators(bone)
end

---
---@param target Entity | Unit
function Unit:MeleeWarpAdjacentToTarget(target)
end

--- TODO.
function Unit:PrintCommandQueue()
end

--- Applies an impulse to the unit (e.g. weapon recoil), usually for ship-rocking
---@param x number
---@param y number
---@param z number
function Unit:RecoilImpulse(x, y, z)
end

--- Allow building of categories for this unit.
-- @param category Unit's category, example categories.TECH1.
function Unit:RemoveBuildRestriction(category)
end

--- Removes a command cap from the unit.
--- Also removes the command button, or disables it, from the UI.
---@param capName CommandCap
function Unit:RemoveCommandCap(capName)
end

--- Remove amount of nuke missiles from the unit
---@param amount number
function Unit:RemoveNukeSiloAmmo(amount)
end

--- Remove amount of tactical missiles from the unit
---@param amount number
function Unit:RemoveTacticalSiloAmmo(amount)
end

--- Removes a toggle cap from the unit.
--- Also removes the command button, or disables it, from the UI.
---@param capName ToggleCap
function Unit:RemoveToggleCap(capName)
end

--- Restore buildable categories to that as defined in the blueprint
function Unit:RestoreBuildRestrictions()
end

--- Restore the command caps of the unit back to blueprint spec.
function Unit:RestoreCommandCaps()
end

--- Restore the toggle caps of the unit back to blueprint spec
function Unit:RestoreToggleCaps()
end

--- Revert the collision shape to the blueprint spec.
function Unit:RevertCollisionShape()
end

--- Revert the elevation of the unit back to the blueperint spec.
function Unit:RevertElevation()
end

--- Restore regen rate of the unit back to blueprint spec
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

--- Set auto silo build mode to on/off
---@param mode boolean
function Unit:SetAutoMode(mode)
end

---
---@param block boolean
function Unit:SetBlockCommandQueue(block)
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

--- Sets if this unit can be captured
---@param capturable boolean
function Unit:SetCapturable(capturable)
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

--- If set to true, enemy units won't target this unit.
--- Accidental hits can still damage it but it enemy units won't lock onto it.
---@param dontTarget boolean
function Unit:SetDoNotTarget(dontTarget)
end

--- Set the elevation of the unit
-- @param TODO.
function Unit:SetElevation()
end

--- Set a specific fire state for the unit's retaliation mode
---@param fireState FireState
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

--- Sets if the unit is able to move
---@param immobile boolean
function Unit:SetImmobile(immobile)
end

---
---@param valid boolean
function Unit:SetIsValidTarget(valid)
end

--- Set if this unit has an overcharge paused
---@param paused boolean
function Unit:SetOverchargePaused(paused)
end

--- Pauses building, upgrading, and other tasks
---@param paused boolean
function Unit:SetPaused(paused)
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

--- Set the regen rate of the unit
---@param rate number
function Unit:SetRegenRate(rate)
end

--- Set the script bit to the desired state
---@param bit number
---@param state boolean
function Unit:SetScriptBit(bit, state)
end

--- Set the shield ratio, `0.0` - `1.0`
---@param ratio number
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

--- Sets if the unit can be selected
---@param flag boolean
function Unit:SetUnSelectable(flag)
end

--- Sets the unit's state
---@param stateName UnitState
---@param bool boolean
function Unit:SetUnitState(stateName, bool)
end

--- Sets the work progress on the unit, `0.0` - `1.0`
---@param progress number
function Unit:SetWorkProgress(progress)
end

--- Makes unit's bone visible.
-- @param bone Bone name or index.
-- @param affectChildren true/false.
function Unit:ShowBone(bone, affectChildren)
end

--- Stops production of a missile
function Unit:StopSiloBuild()
end

--- Test if the unit has this specified set to true in the blueprint spec
---@param capName CommandCap
function Unit:TestCommandCaps(capName)
end

--- Test if the unit has this specified set to true in the blueprint spec
---@param capName ToggleCap
function Unit:TestToggleCaps(capName)
end

--- Toggle the fire state for the retaliation state of the unit
function Unit:ToggleFireState()
end


--- Toggles the script bit that matches the number
---@param bit number
function Unit:ToggleScriptBit(bit)
end

--- Detaches all units from a transport
---@param destroySomeUnits unknown
function Unit:TransportDetachAllUnits(destroySomeUnits)
end

--- Finds out if carrier is full or not
---@return boolean
function Unit:TransportHasAvailableStorage()
end

--- Finds out if the target unit can fit into the carrier
---@param target Unit
---@return boolean
function Unit:TransportHasSpaceFor(target)
end

return Unit
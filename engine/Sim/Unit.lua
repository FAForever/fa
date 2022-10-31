---@meta

---@class moho.unit_methods : moho.entity_methods
local Unit = {}

---@class UnitId: string

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

--- Adds a command cap to the unit
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

--- Calculates the desired world position from the supplied relative vector from the center of the unit.
--- Used for naval factories to set rally point under them.
---@param vector Vector
function Unit:CalculateWorldPositionFromRelative(vector)
end

--- Returns if the unit can build the target unit
---@param blueprintID string
---@return boolean
function Unit:CanBuild(blueprintID)
end

--- Returns if the unit can path to the goal
---@param position Vector
---@return boolean result if false, returns the closest position, else the original position
---@return Vector bestGoal
function Unit:CanPathTo(position)
end

--- Returns if the unit can path to the goal rectangle
--- TODO: find out if it returns position as well
---@param rectangle Rectangle
---@return boolean
function Unit:CanPathToRect(rectangle)
end

---
function Unit:ClearFocusEntity()
end

---
---@param bone Bone
---@param Enable boolean
function Unit:EnableManipulators(bone, Enable)
end

--- Returns the unit's multiplier to a damage type
---@param damageTypeName DamageType
---@return number
function Unit:GetArmorMult(damageTypeName)
end

--- Returns the tactical attack manager object of this unit
---@return Attacker
function Unit:GetAttacker()
end

--- Returns the blip (if any) that the given army has for the unit
---@return Blip?
function Unit:GetBlip(armyIndex)
end

---@return UnitBlueprint
function Unit:GetBlueprint()
end

--- Returns the build rate of a unit
--- @return number
function Unit:GetBuildRate()
end

--- Returns list of unit that the unit is transporting
---@return Unit[]
function Unit:GetCargo()
end

--- Returns table of commands queued up for this unit
---@return OrderInfo[]
function Unit:GetCommandQueue()
end

--- Returns the energy consumption of the unit
---@return number
function Unit:GetConsumptionPerSecondEnergy()
end

--- Returns the mass consumption of the unit
---@return number
function Unit:GetConsumptionPerSecondMass()
end

--- Returns the name of the layer the unit is currently in. This value is cached inside
--- `Unit.Layer` each time the layer changes (when `OnLayerChanged` is called) and the hierarchy
--- is called accordingly (e.g. ends up in `Unit.OnLayerChange`).
---@return Layer
function Unit:GetCurrentLayer()
end

--- Returns the current move location of the unit
---@return Vector
function Unit:GetCurrentMoveLocation()
end

--- Returns the fire state for the unit
---@return FireState
function Unit:GetFireState()
end

---
---@return Unit
function Unit:GetFocusUnit()
end

--- Returns fuel remaining ratio, `0.0` - `1.0`
---@return number
function Unit:GetFuelRatio()
end

--- Returns fuel remaining in seconds
---@return number
function Unit:GetFuelUseTime()
end

--- Returns the unit that is being guarded
---@return Unit | nil
function Unit:GetGuardedUnit()
end

--- Returns the units that are guarding this unit
---@return Unit[]
function Unit:GetGuards()
end

--- Returns current health
---@return number
function Unit:GetHealth()
end

--- Returns the navigator object of this unit
---@return Navigator
function Unit:GetNavigator()
end

--- Returns number of nuclear missiles this unit has available.
--- This is the method to call for both SML's and SMD's.
---@see GetTacticalSiloAmmoCount() # for tactical missiles
---@return number
function Unit:GetNukeSiloAmmoCount()
end

--- Returns number of factory/engineer build orders that fit in the specified category
---@param category EntityCategory
function Unit:GetNumBuildOrders(category)
end

--- Returns the energy production of the unit
---@return number
function Unit:GetProductionPerSecondEnergy()
end

--- Returns the mass production of the unit
---@return number
function Unit:GetProductionPerSecondMass()
end

--- Returns the rally point for the factory
---@return Vector
function Unit:GetRallyPoint()
end

--- Returns the fraction of requested resources this unit consumed last tick.
--- Normally 1, but can be fractional if economy is struggling.
---@return number
function Unit:GetResourceConsumed()
end

--- Returns the current toggle state of the script bit that matches the number
---@param bit number
---@return boolean
function Unit:GetScriptBit(bit)
end

--- Returns the shield ratio, `0.0` - `1.0`
---@return number
function Unit:GetShieldRatio()
end

--- Returns the unit's specific statistics
---@param statName string
---@param defaultVal? number
---@return number
-- Special case for the Salem: GetStat("h1_SetSalemAmph", 0 or 1) will Disable/Enable amphibious mode
function Unit:GetStat(statName, defaultVal)
end

--- Returns number of tactical missiles this unit has available
---@see GetNukeSiloAmmoCount() # for nuclear missiles
---@return number
function Unit:GetTacticalSiloAmmoCount()
end

--- Returns our target unit if we have one
---@return Entity | Unit | nil
function Unit:GetTargetEntity()
end

---@unknown
function Unit:GetTransportFerryBeacon()
end

--- Returns the unit's blueprint ID
---@return UnitId
function Unit:GetUnitId()
end

---
---@return number x
---@return number y
---@return number z
function Unit:GetVelocity()
end

--- Returns the index'th weapon of this unit.
--- Index must be between `1` and self:GetWeaponCount(), inclusive.
---@return Weapon
function Unit:GetWeapon(index)
end

--- Returns the number of weapons on this unit.
--- Note that dummy weapons are not included in the count, so this may differ from
--- the number of weapons defined in the unit's blueprint.
---@return number
function Unit:GetWeaponCount()
end

---
---@return number
function Unit:GetWorkProgress()
end

--- Adds nuclear missiles to the unit.
--- This is the method to call for both SML's and SMD's.
---@see GiveTacticalSiloAmmo() # for tactical missiles
---@param amount number
function Unit:GiveNukeSiloAmmo(amount)
end

--- Adds tactical missiles to the unit
---@see GiveNukeSiloAmmo() # for nuclear missiles
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

--- Makes the unit's bone invisible
---@param bone Bone
---@param affectChildren boolean
function Unit:HideBone(bone, affectChildren)
end

--- Returns if the unit is under construction
---@return boolean
function Unit:IsBeingBuilt()
end

--- Returns if this unit can be captured or not
---@return boolean
function Unit:IsCapturable()
end

--- Returns if the unit is in an Idle state or not
---@return boolean
function Unit:IsIdleState()
end

--- Returns if the unit is mobile
---@return boolean
function Unit:IsMobile()
end

--- Returns if the unit is moving or not
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

---
function Unit:KillManipulator()
end

---
---@param bone Bone
function Unit:KillManipulators(bone)
end

---
---@param target Unit
function Unit:MeleeWarpAdjacentToTarget(target)
end

---
function Unit:PrintCommandQueue()
end

--- Applies an impulse to the unit (e.g. weapon recoil), usually for ship-rocking
---@param x number
---@param y number
---@param z number
function Unit:RecoilImpulse(x, y, z)
end

--- Allows build categories for this unit
---@param category EntityCategory
function Unit:RemoveBuildRestriction(category)
end

--- Removes a command cap from the unit.
--- Also removes the command button, or disables it, from the UI.
---@param capName CommandCap
function Unit:RemoveCommandCap(capName)
end

--- Removes nuclear missiles from the unit.
--- This is the method to call for both SML's and SMD's.
---@see RemoveTacticalSiloAmmo() # for tactical missiles
---@param amount number
function Unit:RemoveNukeSiloAmmo(amount)
end

--- Removes tactical missiles from the unit
---@see RemoveNukeSiloAmmo() # for nuclear missiles
---@param amount number
function Unit:RemoveTacticalSiloAmmo(amount)
end

--- Removes a toggle cap from the unit.
--- Also removes the command button, or disables it, from the UI.
---@param capName ToggleCap
function Unit:RemoveToggleCap(capName)
end

--- Restores buildable categories to that as defined in the blueprint
function Unit:RestoreBuildRestrictions()
end

--- Restores the command caps of the unit back to blueprint spec
function Unit:RestoreCommandCaps()
end

--- Restores the toggle caps of the unit back to blueprint spec
function Unit:RestoreToggleCaps()
end

--- Reverts the collision shape to the blueprint spec
function Unit:RevertCollisionShape()
end

--- Reverts the elevation of the unit back to the blueperint spec
function Unit:RevertElevation()
end

--- Reverts regen rate of the unit back to blueprint spec
function Unit:RevertRegenRate()
end

---
---@param emitter moho.IEffect
function Unit:ScaleGetBuiltEmitter(emitter)
end

--- Sets the acceleration multiplier of the unit
---@param accelMult number
function Unit:SetAccMult(accelMult)
end

--- Sets auto silo build mode to on/off
---@param mode boolean
function Unit:SetAutoMode(mode)
end

---
---@param block boolean
function Unit:SetBlockCommandQueue(block)
end

--- Sets the break off distance multiplier of the unit
---@param mult number
function Unit:SetBreakOffDistanceMult(mult)
end

--- Sets the break off trigger multiplier of the unit.
---@param mult number
function Unit:SetBreakOffTriggerMult(mult)
end

--- Sets the build rate of the unit
---@param rate number
function Unit:SetBuildRate(rate)
end

---
---@param busy boolean
function Unit:SetBusy(busy)
end

--- Sets if this unit can be captured or not
---@param capturable boolean
function Unit:SetCapturable(capturable)
end

---
---@param active boolean
function Unit:SetConsumptionActive(active)
end

--- Sets the energy consumption of the unit
---@param amount number
function Unit:SetConsumptionPerSecondEnergy(amount)
end

--- Sets the mass consumption of the unit
---@param amount number
function Unit:SetConsumptionPerSecondMass(amount)
end

--- Sets the creator for this unit.
--- Used for example for UEF ACU pods or Kennel pods.
---@param unit Unit
function Unit:SetCreator(unit)
end

--- Sets a custom name for the unit, displayed in green text
---@param name string
function Unit:SetCustomName(name)
end

--- Sets if enemy units won't target this unit.
--- Accidental hits can still damage it but it enemy units won't lock onto it.
---@param dontTarget boolean
function Unit:SetDoNotTarget(dontTarget)
end

--- Sets the elevation of the unit
---@param elevation number
function Unit:SetElevation(elevation)
end

--- Sets a specific fire state for the unit's retaliation mode
---@param fireState FireState
function Unit:SetFireState(fireState)
end

---
---@param focus Entity | Unit | Prop | Projectile
function Unit:SetFocusEntity(focus)
end

--- Sets how much fuel has the unit left, `0.0` - `1.0`
---@param ratio number
function Unit:SetFuelRatio(ratio)
end

--- Sets the fuel use time in seconds
---@param time number
function Unit:SetFuelUseTime(time)
end

--- Sets if the unit is able to move
---@param immobile boolean
function Unit:SetImmobile(immobile)
end

---
---@param valid boolean
function Unit:SetIsValidTarget(valid)
end

--- Sets if this unit's overcharge is paused
---@param paused boolean
function Unit:SetOverchargePaused(paused)
end

--- Pauses building, upgrading, and other tasks
---@param paused boolean
function Unit:SetPaused(paused)
end

--- Enables or disables resource production for the unit.
--- Used for mass fabricators or extractors for example.
---@param active boolean
function Unit:SetProductionActive(active)
end

--- Sets the production of energy of the unit
---@param amount number
function Unit:SetProductionPerSecondEnergy(amount)
end

--- Sets the production of mass of the unit
---@param amount number
function Unit:SetProductionPerSecondMass(amount)
end

--- Sets if this unit can be reclaimed or not
---@param reclaimable boolean
function Unit:SetReclaimable(reclaimable)
end

--- Sets the regen rate of the unit
---@param rate number
function Unit:SetRegenRate(rate)
end

--- Sets the script bit to the desired state
---@param bit number
---@param state boolean
function Unit:SetScriptBit(bit, state)
end

--- Sets the shield ratio, `0.0` - `1.0`
---@param ratio number
function Unit:SetShieldRatio(ratio)
end

--- Sets the speed multiplier of the unit
---@param mult number
function Unit:SetSpeedMult(mult)
end

--- Sets the unit statistic
---@param name string
---@param value number
function Unit:SetStat(name, value)
end

--- Sets the icon underlay to set texture.
--- Used in campaign to highlight objetcive targets.
---@param icon string
function Unit:SetStrategicUnderlay(icon)
end

--- Stuns the unit for the set time in seconds
---@param time number
function Unit:SetStunned(time)
end

--- Sets the turn multiplier of the unit
---@param mult number
function Unit:SetTurnMult(mult)
end

--- Sets if the unit can be selected
---@param unselectable boolean
function Unit:SetUnSelectable(unselectable)
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

--- Makes unit's bone visible
---@param bone Bone
---@param affectChildren boolean
function Unit:ShowBone(bone, affectChildren)
end

--- Stops production of a missile
function Unit:StopSiloBuild()
end

--- Tests if the unit has this command cap specified in the blueprint spec
---@param capName CommandCap
function Unit:TestCommandCaps(capName)
end

--- Tests if the unit has this toggle cap specified in the blueprint spec
---@param capName ToggleCap
function Unit:TestToggleCaps(capName)
end

--- Toggles the fire state for the retaliation state of the unit
function Unit:ToggleFireState()
end

--- Toggles the script bit
---@param bit number
function Unit:ToggleScriptBit(bit)
end

--- Detaches all units from a transport
---@param destroySomeUnits unknown
function Unit:TransportDetachAllUnits(destroySomeUnits)
end

--- Returns if carrier is full or not
---@return boolean
function Unit:TransportHasAvailableStorage()
end

--- Returns if the target unit can fit into the carrier
---@param target Unit
---@return boolean
function Unit:TransportHasSpaceFor(target)
end

return Unit
---@meta

---@class moho.unit_methods : moho.entity_methods
local Unit = {}

---@alias FocusObject Entity | Unit | Prop | Projectile

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
---| "Sacrificing"

---@class UnitCommand
---@field _c_object userdata
---@field blueprintId? string -- For build commands
---@field commandType integer -- Integer representation of CommandType, see UnitQueueDataToCommand for details
---@field target? Prop|Unit|Entity -- For commands that target an entity
---@field targetId? EntityId
---@field x number -- X coordinate of command target
---@field y number -- Y coordinate of command target
---@field z number -- Z coordinate of command target

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
---@return Vector
function Unit:CalculateWorldPositionFromRelative(vector)
end

--- returns true if the unit can build the target unit
---@param blueprintID string
---@return boolean
function Unit:CanBuild(blueprintID)
end

--- returns true if the unit can path to the goal
---@param position Vector
---@return boolean result if false, returns the closest position, else the original position
---@return Vector bestGoal
function Unit:CanPathTo(position)
end

--- returns true if the unit can path to the goal rectangle
--- TODO: find out if it returns position as well
---@param rectangle Rectangle
---@return boolean
function Unit:CanPathToRect(rectangle)
end

function Unit:ClearFocusEntity()
end

---@param bone Bone
---@param Enable boolean
function Unit:EnableManipulators(bone, Enable)
end

---Forces game to use AltFootprint for the unit
---@param state boolean
function Unit:ForceAltFootprint(state)
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
---@return UnitCommand[]
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
---@return Vector | false
function Unit:GetCurrentMoveLocation()
end

--- Returns the fire state for the unit
---@return FireState
function Unit:GetFireState()
end

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

--- Returns the navigator object of this unit. 
--- 
--- Returns `nil` for immobile units.
---@return Navigator?
function Unit:GetNavigator()
end

--- Returns number of nuclear missiles this unit has available.
--- This is the method to call for both SML's and SMD's.
---@see moho.unit_methods.GetTacticalSiloAmmoCount # for tactical missiles
---@return number
function Unit:GetNukeSiloAmmoCount()
end

--- Returns number of factory/engineer build orders that fit in the specified category
---@param category EntityCategory
---@return integer
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

---@class UnitStat
---@field Value number

--- Returns the unit's specific statistics
---@param statName string
---@param defaultVal? number
---@return UnitStat
function Unit:GetStat(statName, defaultVal)
end

--- Returns number of tactical missiles this unit has available
---@see moho.unit_methods.GetNukeSiloAmmoCount # for nuclear missiles
---@return number
function Unit:GetTacticalSiloAmmoCount()
end

--- Returns our target unit if we have one
---@return Entity | Unit | Prop | nil
function Unit:GetTargetEntity()
end

---@unknown
function Unit:GetTransportFerryBeacon()
end

--- Returns the unit's blueprint ID
---@return EntityId
function Unit:GetUnitId()
end

--- Returns unit velocity in ogrids/tick
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

---@return number
function Unit:GetWorkProgress()
end

--- With [FA-Binary-Patches#15](https://github.com/FAForever/FA-Binary-Patches/pull/15),
--- `InBlocks` makes `amount` set the number of "blocks" for the in-progress tactical or nuclear missile.
--- A projectile is built out of `10 * (buildTime / buildRate)` blocks.
--- Use `Unit:GiveNukeSiloBlocks()` to use this feature.

--- Adds nuclear missiles to the unit
---@see moho.unit_methods.GiveTacticalSiloAmmo # for tactical missiles
---@param amount number
---@param inBlocks? boolean
function Unit:GiveNukeSiloAmmo(amount, inBlocks)
end

--- Adds tactical missiles to the unit
---@see moho.unit_methods.GiveNukeSiloAmmo # for nuclear missiles
---@param amount number
function Unit:GiveTacticalSiloAmmo(amount)
end

---@param target Entity | Unit
---@return boolean
function Unit:HasMeleeSpaceAroundTarget(target)
end

---@return boolean
function Unit:HasValidTeleportDest()
end

--- makes the unit's bone invisible
---@param bone Bone
---@param affectChildren? boolean
function Unit:HideBone(bone, affectChildren)
end

--- returns true if the unit is under construction
---@return boolean
function Unit:IsBeingBuilt()
end

--- returns true if this unit can be captured or not
---@return boolean
function Unit:IsCapturable()
end

--- returns true if the unit is in an Idle state or not
---@return boolean
function Unit:IsIdleState()
end

--- returns true if the unit is mobile
---@return boolean
function Unit:IsMobile()
end

--- Returns true if the position has changed with respect to the previous simulation tick
---@return boolean
function Unit:IsMoving()
end

--- returns true if the unit has paused overcharge
---@return boolean
function Unit:IsOverchargePaused()
end

--- returns true if the unit is paused
---@return boolean
function Unit:IsPaused()
end

--- returns true if the unit is stunned
---@return boolean
function Unit:IsStunned()
end

--- returns true if the unit is in given state
---@param stateName UnitState
---@return boolean
function Unit:IsUnitState(stateName)
end

---@return boolean
function Unit:IsValidTarget()
end

function Unit:KillManipulator()
end

---@param bone Bone
function Unit:KillManipulators(bone)
end

---@param target Unit
function Unit:MeleeWarpAdjacentToTarget(target)
end

function Unit:PrintCommandQueue()
end

--- applies an impulse to the unit (e.g. weapon recoil), usually for ship-rocking
---@param x number
---@param y number
---@param z number
function Unit:RecoilImpulse(x, y, z)
end

--- allows build categories for this unit
---@param category EntityCategory
function Unit:RemoveBuildRestriction(category)
end

--- Removes a command cap from the unit.
--- Also removes the command button (or disables it if a default cap) from the UI.
---@param capName CommandCap
function Unit:RemoveCommandCap(capName)
end

--- Removes nuclear missiles from the unit.
--- This is the method to call for both SML's and SMD's.
---@see moho.unit_methods.RemoveTacticalSiloAmmo # for tactical missiles
---@param amount number
function Unit:RemoveNukeSiloAmmo(amount)
end

--- Removes tactical missiles from the unit
---@see moho.unit_methods.RemoveNukeSiloAmmo # for nuclear missiles
---@param amount number
function Unit:RemoveTacticalSiloAmmo(amount)
end

--- Removes a toggle cap from the unit.
--- Also removes the command button (or disables it if a default cap) from the UI.
---@param capName ToggleCap
function Unit:RemoveToggleCap(capName)
end

--- restores buildable categories to that as defined in the blueprint
function Unit:RestoreBuildRestrictions()
end

--- restores the command caps of the unit back to blueprint spec
function Unit:RestoreCommandCaps()
end

--- restores the toggle caps of the unit back to blueprint spec
function Unit:RestoreToggleCaps()
end

--- reverts the collision shape to the blueprint spec
function Unit:RevertCollisionShape()
end

--- reverts the elevation of the unit back to the blueperint spec
function Unit:RevertElevation()
end

--- reverts the regen rate of the unit back to blueprint spec
function Unit:RevertRegenRate()
end

---@param emitter moho.IEffect
function Unit:ScaleGetBuiltEmitter(emitter)
end

--- Sets the acceleration multiplier of the unit
---@param accelMult number
function Unit:SetAccMult(accelMult)
end

--- enable silo auto-build or unit auto-assist
---@param mode boolean
function Unit:SetAutoMode(mode)
end

---@param block boolean
function Unit:SetBlockCommandQueue(block)
end

--- sets the break off distance multiplier of the unit
---@param mult number
function Unit:SetBreakOffDistanceMult(mult)
end

--- sets the break off trigger multiplier of the unit
---@param mult number
function Unit:SetBreakOffTriggerMult(mult)
end

--- sets the build rate of the unit
---@param rate number
function Unit:SetBuildRate(rate)
end

---@param busy boolean
function Unit:SetBusy(busy)
end

--- sets if this unit can be captured or not
---@param capturable boolean
function Unit:SetCapturable(capturable)
end

---@param active boolean
function Unit:SetConsumptionActive(active)
end

--- sets the energy consumption of the unit
---@param amount number
function Unit:SetConsumptionPerSecondEnergy(amount)
end

--- sets the mass consumption of the unit
---@param amount number
function Unit:SetConsumptionPerSecondMass(amount)
end

--- Sets the creator for this unit.
--- Used for example for UEF ACU pods or Kennel pods.
---@param unit Unit
function Unit:SetCreator(unit)
end

--- sets a custom name for the unit, displayed in green text
---@param name string | number
function Unit:SetCustomName(name)
end

--- Sets if enemy units won't target this unit.
--- Accidental hits can still damage it but enemy units won't lock onto it.
---@param dontTarget boolean
function Unit:SetDoNotTarget(dontTarget)
end

--- sets the elevation of the unit
---@param elevation number
function Unit:SetElevation(elevation)
end

--- sets a specific fire state for the unit's retaliation mode
---@param fireState FireState
function Unit:SetFireState(fireState)
end

---@param focus FocusObject
function Unit:SetFocusEntity(focus)
end

--- sets how much fuel has the unit left, `0.0` - `1.0`
---@param ratio number
function Unit:SetFuelRatio(ratio)
end

--- sets the fuel use time in seconds
---@param time number
function Unit:SetFuelUseTime(time)
end

--- sets if the unit is able to move
---@param immobile boolean
function Unit:SetImmobile(immobile)
end

---@param valid boolean
function Unit:SetIsValidTarget(valid)
end

--- sets if this unit's overcharge is paused
---@param paused boolean
function Unit:SetOverchargePaused(paused)
end

--- Pauses building, upgrading, and other tasks this unit can perform.
--- Assisting units are unaffected.
---@param paused boolean
function Unit:SetPaused(paused)
end

--- Enables or disables resource production for the unit.
--- Used for mass fabricators or extractors for example.
---@param active boolean
function Unit:SetProductionActive(active)
end

--- sets the production of energy of the unit
---@param amount number
function Unit:SetProductionPerSecondEnergy(amount)
end

--- sets the production of mass of the unit
---@param amount number
function Unit:SetProductionPerSecondMass(amount)
end

--- sets if this unit can be reclaimed or not
---@param reclaimable boolean
function Unit:SetReclaimable(reclaimable)
end

--- sets the regen rate of the unit
---@param rate number
function Unit:SetRegenRate(rate)
end

--- sets the script bit, which calls `OnScriptBitSet` or `OnScriptBitClear` for the Sim Unit and `OnSelectionChanged` on the User side if the bit is toggled
---@param bit ToggleCap
---@param state boolean # `true` -> `OnScriptBitSet`; `false` -> `OnScriptBitClear`
function Unit:SetScriptBit(bit, state)
end

--- sets the shield ratio, `0.0` - `1.0`
---@param ratio number
function Unit:SetShieldRatio(ratio)
end

--- sets the speed multiplier of the unit
---@param mult number
function Unit:SetSpeedMult(mult)
end

--- sets the unit statistic
---@param name string
---@param value number
function Unit:SetStat(name, value)
end

--- Sets the icon underlay to a given texture. 
--- 
--- The provided string is used as a lookup to find the relevant textures in `fa/textures/ui/common/game/strategicicons`. It ends up using:
---
--- - fa/textures/ui/common/game/strategicicons/x_over.dds
--- - fa/textures/ui/common/game/strategicicons/x_rest.dds
--- - fa/textures/ui/common/game/strategicicons/x_selected.dds
--- - fa/textures/ui/common/game/strategicicons/x_selectedover.dds
---
--- Where `x` is the string provided.
--- Often used in campaign to highlight objective targets.
---@param icon 'icon_objective_primary' | 'icon_objective_secondary' | 'icon_objective_bonus' | string
function Unit:SetStrategicUnderlay(icon)
end

--- stuns the unit for the set time in seconds
---@param time number
function Unit:SetStunned(time)
end

--- sets the turn multiplier of the unit
---@param mult number
function Unit:SetTurnMult(mult)
end

--- sets if the unit can be selected
---@param unselectable boolean
function Unit:SetUnSelectable(unselectable)
end

--- sets the unit's state
---@param stateName UnitState
---@param bool boolean
function Unit:SetUnitState(stateName, bool)
end

--- sets the work progress on the unit, `0.0` - `1.0`
---@param progress number
function Unit:SetWorkProgress(progress)
end

--- makes the unit's bone visible, and if `affectChildren` is true, all child bones as well
--- (this is almost always what you want)
---@param bone Bone
---@param affectChildren? boolean
function Unit:ShowBone(bone, affectChildren)
end

--- stops production of a missile
function Unit:StopSiloBuild()
end

--- Tests if the unit has this command cap specified in the blueprint spec.
--- May not always work.
---@param capName CommandCap
function Unit:TestCommandCaps(capName)
end

--- Tests if the unit has this toggle cap specified in the blueprint spec.
--- May not always work.
---@param capName ToggleCap
---@return boolean
function Unit:TestToggleCaps(capName)
end

--- toggles the fire state for the retaliation state of the unit
function Unit:ToggleFireState()
end

--- toggles the script bit
---@param bit number
function Unit:ToggleScriptBit(bit)
end

--- detaches all units from this transport
---@param destroySomeUnits unknown
function Unit:TransportDetachAllUnits(destroySomeUnits)
end

--- returns true if this transport is full or not
---@return boolean
function Unit:TransportHasAvailableStorage()
end

--- returns true if the target unit can fit into this transport
---@param target Unit
---@return boolean
function Unit:TransportHasSpaceFor(target)
end

--- Called by the engine when the unit starts a build order, to check if it may build the blueprint. Returning false skips the build.
---@type nil | fun(self: Unit, blueprint: UnitBlueprint): boolean
Unit.CheckBuildRestriction = nil

--- Called by the engine before it kills the unit, and to allow a self-destruct order.
--- Returning false cancels the kill, unless the unit is a commander outside the playable area.
--- When a transport is destroyed, its cargo is killed only if this returns true.
---@type nil | fun(self: Unit, other: Unit): boolean
Unit.CheckCanBeKilled = nil

--- Called by the engine on a commander in a destroyed transport when `CheckCanBeKilled` returned false.
--- Returning true deals 10000 damage to the commander instead of killing it.
---@type nil | fun(self: Unit, transport: Unit): boolean
Unit.CheckCanTakeDamage = nil

--- Called by the engine when the unit's repair task ends.
---@type nil | fun(self: Unit)
Unit.ClearWork = nil

--- Called by the engine when the unit is fully reclaimed, to create its wreck. The engine passes 0 as the overkill ratio.
--- The reclaimer continues on the returned prop.
---@type nil | fun(self: Unit, overkillRatio: number): Prop | nil
Unit.CreateWreckageProp = nil

--- Called by the engine on a unit in a transport's storage, right before the engine destroys it with the transport.
---@type nil | fun(self: Unit)
Unit.DestroyedOnTransport = nil

--- Called by the engine on each unit attached to a capture target.
--- Returns the time in seconds, energy cost and mass cost to capture it. The engine adds up the results.
---@type nil | fun(self: Unit, target: Unit): number, number, number
Unit.GetCaptureCosts = nil

--- Called by the engine when the unit starts building silo ammo. Returns the build rate.
---@type nil | fun(self: Unit): number
Unit.GetEconomyBuildRate = nil

--- Called by the engine when the unit starts building silo ammo. Returns the multiplier for the ammo's energy cost.
---@type nil | fun(self: Unit): number
Unit.GetEnergyBuildAdjMod = nil

--- Called by the engine when the unit starts building silo ammo. Returns the multiplier for the ammo's mass cost.
---@type nil | fun(self: Unit): number
Unit.GetMassBuildAdjMod = nil

--- Called by the engine on an unfinished unit when a builder starts rebuilding it.
--- Returns a number the engine multiplies with the unit's build progress.
---@type nil | fun(self: Unit, blueprint: UnitBlueprint): number
Unit.GetRebuildBonus = nil

--- Called by the engine each tick of reclaiming.
--- Returns the time in seconds, energy and mass to reclaim the target at full health.
---@type nil | fun(self: Unit, target: Unit | Prop): number, number, number
Unit.GetReclaimCosts = nil

--- Called by the engine when it creates each weapon of the unit. Returns the Lua class for the weapon.
--- The engine passes the weapon's blueprint label, or its index when the label is empty.
---@type nil | fun(self: Unit, label: string | integer): Weapon
Unit.GetWeaponClass = nil

--- Called by the engine when the unit starts repairing a unit that is upgrading.
---@type nil | fun(self: Unit, target: Unit)
Unit.InheritWork = nil

--- Called by the engine when the unit is put into a transport's storage.
---@type nil | fun(self: Unit, transport: Unit)
Unit.OnAddToStorage = nil

--- Called by the engine on both units when a structure finishes building next to another structure.
---@type nil | fun(self: Unit, adjacentUnit: Unit, triggerUnit: Unit)
Unit.OnAdjacentTo = nil

--- Called by the engine when a bone watched by a collision manipulator turns away from the unit's orientation.
---@type nil | fun(self: Unit, bone: string, x: number, y: number, z: number)
Unit.OnAnimCollision = nil

--- Called by the engine when a bone watched by a collision manipulator goes below the terrain.
---@type nil | fun(self: Unit, bone: string, x: number, y: number, z: number)
Unit.OnAnimTerrainCollision = nil

--- Called by the engine when the unit's focus entity changes to a new entity.
---@type nil | fun(self: Unit)
Unit.OnAssignedFocusEntity = nil

--- Called by the engine when auto mode is turned off.
---@type nil | fun(self: Unit)
Unit.OnAutoModeOff = nil

--- Called by the engine when auto mode is turned on.
---@type nil | fun(self: Unit)
Unit.OnAutoModeOn = nil

--- Called by the engine when a builder progresses the unit's construction.
---@type nil | fun(self: Unit, builder: Unit, oldProg: number, newProg: number)
Unit.OnBeingBuiltProgress = nil

--- Called by the engine when the unit progresses its build target.
---@type nil | fun(self: Unit, target: Unit, oldProg: number, newProg: number)
Unit.OnBuildProgress = nil

--- Called by the engine when the unit is captured.
---@type nil | fun(self: Unit, captor: Unit)
Unit.OnCaptured = nil

--- Called by the engine when the unit's resource consumption turns on.
---@type nil | fun(self: Unit)
Unit.OnConsumptionActive = nil

--- Called by the engine when the unit's resource consumption turns off.
---@type nil | fun(self: Unit)
Unit.OnConsumptionInActive = nil

--- Called by the engine after the unit is constructed.
---@type nil | fun(self: Unit)
Unit.OnCreate = nil

--- Called by the engine when the unit takes point damage, with the index of the instigator's army.
---@type nil | fun(self: Unit, armyIndex: integer)
Unit.OnDamageBy = nil

--- Called by the engine when a decaying unit reaches 0 health.
---@type nil | fun(self: Unit)
Unit.OnDecayed = nil

--- Called by the engine when an army creates a new blip for the unit.
---@type nil | fun(self: Unit, armyIndex: integer)
Unit.OnDetectedBy = nil

--- Called by the engine when the unit takes >= 2 times as much damage due to armor multi or handicap divisor.
---@type nil | fun(self: Unit, type: DamageType)
Unit.OnExtraDamageDealt = nil

--- Called by the engine when a capture of this unit fails.
---@type nil | fun(self: Unit, captor: Unit)
Unit.OnFailedBeingCaptured = nil

--- Called by the engine when the unit fails to capture its target.
---@type nil | fun(self: Unit, target: Unit)
Unit.OnFailedCapture = nil

--- Called by the engine when a teleport order of the unit fails.
---@type nil | fun(self: Unit)
Unit.OnFailedTeleport = nil

--- Called by the engine when the unit is removed before its construction finished.
---@type nil | fun(self: Unit)
Unit.OnFailedToBeBuilt = nil

--- Called by the engine when the unit stops building before its target finished.
---@type nil | fun(self: Unit)
Unit.OnFailedToBuild = nil

--- Called by the engine when the unit gets a ferry order.
---@type nil | fun(self: Unit)
Unit.OnFerryPointSet = nil

--- Called by the engine when the unit was out of fuel and recharges fuel (either by air staging or by landing).
---@type nil | fun(self: Unit)
Unit.OnGotFuel = nil

--- Called by the engine when the falling unit hits the ground or the water.
---@type nil | fun(self: Unit, with: "Terrain" | "Water")
Unit.OnImpact = nil

--- Called by the engine when the unit is killed.
---@type nil | fun(self: Unit, instigator: Unit | Projectile | nil, type: DamageType, overkillRatio: number)
Unit.OnKilled = nil

--- Called by the engine when the horizontal movement state of the unit changes.
---@type nil | fun(self: Unit, new: HorizontalMovementState, old: HorizontalMovementState)
Unit.OnMotionHorzEventChange = nil

--- Called by the engine when a unit changes motion state,
--- usually when it attaches/detaches from other entities such as transports.
---@type nil | fun(self: Unit, new: MotionState, old: MotionState)
Unit.OnMotionStateChange = nil

--- Called by the engine when the turning state of an air unit changes.
---@type nil | fun(self: Unit, new: string, old: string)
Unit.OnMotionTurnEventChange = nil

--- Called by the engine when the vertical movement state of the unit changes.
---@type nil | fun(self: Unit, new: VerticalMovementState, old: VerticalMovementState)
Unit.OnMotionVertEventChange = nil

--- Called by the engine on both units when one of two adjacent structures is killed or destroyed.
---@type nil | fun(self: Unit, adjacentUnit: Unit)
Unit.OnNotAdjacentTo = nil

--- Called by the engine when a bone watched by a collision manipulator comes back above the terrain.
---@type nil | fun(self: Unit, bone: string, x: number, y: number, z: number)
Unit.OnNotAnimTerrainCollision = nil

--- Called by the engine when the unit finishes building silo ammo, after `OnSiloBuildEnd`.
---@type nil | fun(self: Unit, weapon: Weapon)
Unit.OnNukeArmed = nil

--- Called by the engine when the unit fires a nuke.
---@type nil | fun(self: Unit)
Unit.OnNukeLaunched = nil

--- Called by the engine when the unit is paused.
---@type nil | fun(self: Unit)
Unit.OnPaused = nil

--- Called by the engine while the unit is constructed, before its intel and weapons exist. `OnCreate` follows.
---@type nil | fun(self: Unit)
Unit.OnPreCreate = nil

--- Called by the engine when the builder arm of the unit starts aiming at its build target.
---@type nil | fun(self: Unit)
Unit.OnPrepareArmToBuild = nil

--- Called by the engine when `SetProductionActive(true)` or the `DebugSetProductionActive` console command turns production on.
---@type nil | fun(self: Unit)
Unit.OnProductionActive = nil

--- Called by the engine when `SetProductionActive(false)` or the `DebugSetProductionInActive` console command turns production off.
---@type nil | fun(self: Unit)
Unit.OnProductionInActive = nil

--- Called by the engine when the unit is reclaimed.
---@type nil | fun(self: Unit, reclaimer: Unit)
Unit.OnReclaimed = nil

--- Called by the engine when the unit is taken out of a transport's storage.
---@type nil | fun(self: Unit, transport: Unit)
Unit.OnRemoveFromStorage = nil

--- Called by the engine when the unit runs out of fuel.
---@type nil | fun(self: Unit)
Unit.OnRunOutOfFuel = nil

--- Called by the engine when a script bit of the unit turns off.
---@type nil | fun(self: Unit, bit: UnitScriptBit)
Unit.OnScriptBitClear = nil

--- Called by the engine when a script bit of the unit turns on.
---@type nil | fun(self: Unit, bit: UnitScriptBit)
Unit.OnScriptBitSet = nil

--- Called by the engine on a unit built by a mobile builder when the unit's blueprint has `General.SeedUnit`.
---@type nil | fun(self: Unit, seedUnit: string)
Unit.OnSeedUnitBuilt = nil

--- Called by the engine when the unit finishes building silo ammo.
---@type nil | fun(self: Unit, weapon: Weapon)
Unit.OnSiloBuildEnd = nil

--- Called by the engine when the unit starts building silo ammo.
---@type nil | fun(self: Unit, weapon: Weapon)
Unit.OnSiloBuildStart = nil

--- Called by the engine when the unit gets a special action order.
---@type nil | fun(self: Unit, location: Vector)
Unit.OnSpecialAction = nil

--- Called by the engine when construction of the unit starts.
---@type nil | fun(self: Unit, builder: Unit, layer: Layer)
Unit.OnStartBeingBuilt = nil

--- Called by the engine when a unit starts to capture this unit.
---@type nil | fun(self: Unit, captor: Unit)
Unit.OnStartBeingCaptured = nil

--- Called by the engine when the unit starts building a unit.
---@type nil | fun(self: Unit, built: Unit, order: BuildOrderType)
Unit.OnStartBuild = nil

--- Called by the engine when the builder arm of the unit starts tracking its build target.
---@type nil | fun(self: Unit)
Unit.OnStartBuilderTracking = nil

--- Called by the engine when the unit starts capturing a target.
---@type nil | fun(self: Unit, target: Unit)
Unit.OnStartCapture = nil

--- Called by the engine when the unit starts reclaiming a target.
---@type nil | fun(self: Unit, target: Unit | Prop)
Unit.OnStartReclaim = nil

--- Called by the engine when the unit starts refueling at an air staging platform.
---@type nil | fun(self: Unit)
Unit.OnStartRefueling = nil

--- Called by the engine when repeat build is turned on.
---@type nil | fun(self: Unit)
Unit.OnStartRepeatQueue = nil

--- Called by the engine when the unit starts sacrificing itself into a target.
---@type nil | fun(self: Unit, target: Unit)
Unit.OnStartSacrifice = nil

--- Called by the engine when the unit starts moving to a transport to be loaded.
---@type nil | fun(self: Unit, transport: Unit, bone: Bone)
Unit.OnStartTransportBeamUp = nil

--- Called by the engine when the transport starts loading units.
---@type nil | fun(self: Unit)
Unit.OnStartTransportLoading = nil

--- Called by the engine when construction of the unit finishes.
---@type nil | fun(self: Unit, builder: Unit, layer: Layer)
Unit.OnStopBeingBuilt = nil

--- Called by the engine when a unit finishes capturing this unit.
---@type nil | fun(self: Unit, captor: Unit)
Unit.OnStopBeingCaptured = nil

--- Called by the engine when the unit stops building a unit.
---@type nil | fun(self: Unit, built: Unit, order: string)
Unit.OnStopBuild = nil

--- Called by the engine when the builder arm of the unit stops tracking its build target.
---@type nil | fun(self: Unit)
Unit.OnStopBuilderTracking = nil

--- Called by the engine when the unit stops capturing a target.
---@type nil | fun(self: Unit, target: Unit)
Unit.OnStopCapture = nil

--- Called by the engine when the unit stops reclaiming a target.
---@type nil | fun(self: Unit, target: Unit | Prop)
Unit.OnStopReclaim = nil

--- Called by the engine when repeat build is turned off.
---@type nil | fun(self: Unit)
Unit.OnStopRepeatQueue = nil

--- Called by the engine when the unit stops sacrificing itself into a target.
---@type nil | fun(self: Unit, target: Unit)
Unit.OnStopSacrifice = nil

--- Called by the engine when the unit stops moving to a transport to be loaded.
---@type nil | fun(self: Unit)
Unit.OnStopTransportBeamUp = nil

--- Called by the engine when the transport stops loading units.
---@type nil | fun(self: Unit)
Unit.OnStopTransportLoading = nil

--- Called by the engine when the unit is teleported.
---@type nil | fun(self: Unit, teleporter: Unit, location: Vector, orientation: Quaternion)
Unit.OnTeleportUnit = nil

--- Called by the engine when the terrain type under the unit changes.
---@type nil | fun(self: Unit, new: TerrainType, old: TerrainType)
Unit.OnTerrainTypeChange = nil

--- Called by the engine when the transport ends a load order before all units are loaded.
---@type nil | fun(self: Unit)
Unit.OnTransportAborted = nil

--- Called by the engine when a unit attaches to the transport.
---@type nil | fun(self: Unit, attachBone: Bone, attachedUnit: Unit)
Unit.OnTransportAttach = nil

--- Called by the engine when a unit detaches from the transport.
---@type nil | fun(self: Unit, attachBone: Bone, detachedUnit: Unit)
Unit.OnTransportDetach = nil

--- Called by the engine when the transport starts a load order.
---@type nil | fun(self: Unit)
Unit.OnTransportOrdered = nil

--- Called by the engine when the transport can't carry a unit that was ordered into it.
---@type nil | fun(self: Unit)
Unit.OnTransportReject = nil

--- Called by the engine when the unit is unpaused.
---@type nil | fun(self: Unit)
Unit.OnUnpaused = nil

--- Called by the engine when the unit is killed, before `OnKilled`, and when it is destroyed.
---@type nil | fun(self: Unit)
Unit.SetDead = nil

--- Called by the engine when deciding whether to repair or guard a shield unit. Returns true if its shield is on.
---@type nil | fun(self: Unit): boolean
Unit.ShieldIsOn = nil

return Unit

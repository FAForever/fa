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
---@field target? Prop|Unit|Entity -- For commands that target an entity

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

--- Adds unit to the storage of the carrier. When the storage is full, logs a warning instead
---@see moho.unit_methods.TransportHasAvailableStorage # Checked before adding the unit
---@see moho.unit_methods.OnAddToStorage # Called on the stored unit
---@see UnitBlueprintTransport.StorageSlots # Number of units the storage holds
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

--- Gets the unit's focus unit, which is usually the unit it is building/repairing/reclaiming/capturing.
--- The focus may be set to an Entity (usually a Shield) or a Projectile, in which case this
--- will return nil.
---
---@see Unit.SetFocusEntity
---@return Unit?
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
---@see moho.unit_methods.GetTacticalSiloAmmoCount # For tactical missiles
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
---@see moho.unit_methods.GetNukeSiloAmmoCount # For nuclear missiles
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
---@see moho.unit_methods.GiveTacticalSiloAmmo # For tactical missiles
---@param amount number
---@param inBlocks? boolean
function Unit:GiveNukeSiloAmmo(amount, inBlocks)
end

--- Adds tactical missiles to the unit
---@see moho.unit_methods.GiveNukeSiloAmmo # For nuclear missiles
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
---@see moho.unit_methods.RemoveTacticalSiloAmmo # For tactical missiles
---@param amount number
function Unit:RemoveNukeSiloAmmo(amount)
end

--- Removes tactical missiles from the unit
---@see moho.unit_methods.RemoveNukeSiloAmmo # For nuclear missiles
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
---@see moho.unit_methods.OnAutoModeOn # Called when `mode` is true
---@see moho.unit_methods.OnAutoModeOff # Called when `mode` is false
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

--- Turns the resource consumption of the unit on or off
---@see moho.unit_methods.OnConsumptionActive # Called when `active` is true
---@see moho.unit_methods.OnConsumptionInActive # Called when `active` is false
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

--- Sets the focus entity of the unit. 
--- Usually set by the engine when an engineer starts building/repairing/reclaiming/capturing units.
--- Shield units set their shield entity as the focus to make it repairable.
---
---@see Unit.GetFocusUnit
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
---@see moho.unit_methods.OnPaused # Called when `paused` is true
---@see moho.unit_methods.OnUnpaused # Called when `paused` is false
---@param paused boolean
function Unit:SetPaused(paused)
end

--- Enables or disables resource production for the unit.
--- Used for mass fabricators or extractors for example.
---@see moho.unit_methods.OnProductionActive # Called when `active` is true
---@see moho.unit_methods.OnProductionInActive # Called when `active` is false
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
---@see moho.unit_methods.OnScriptBitSet
---@see moho.unit_methods.OnScriptBitClear
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
---@see categories.SELECTABLE # Rules for which units are selectable
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
---@see moho.unit_methods.OnScriptBitSet
---@see moho.unit_methods.OnScriptBitClear
---@param bit number
function Unit:ToggleScriptBit(bit)
end

--- detaches all units from this transport
---@see moho.unit_methods.CheckCanBeKilled # Called on attached units when `destroySomeUnits` is true
---@see moho.unit_methods.DestroyedOnTransport # Called on units in storage before destroying them
---@param destroySomeUnits boolean # `true` kills each attached unit with a 99% chance instead of detaching it, as when the transport dies
function Unit:TransportDetachAllUnits(destroySomeUnits)
end

--- Returns whether the storage has room for another unit: the stored and reserved units are fewer than `StorageSlots`
---@see moho.unit_methods.AddUnitToStorage # Adds a unit to the storage when this is true
---@see UnitBlueprintTransport.StorageSlots # Number of units the storage holds
---@return boolean
function Unit:TransportHasAvailableStorage()
end

--- returns true if the target unit can fit into this transport
---@param target Unit
---@return boolean
function Unit:TransportHasSpaceFor(target)
end

--- Called by the engine when the unit starts a build order, to check if it may build the blueprint. Returning false skips the build
---@type nil | fun(self: Unit, blueprint: UnitBlueprint): boolean
Unit.CheckBuildRestriction = nil

--- Called by the engine before `Kill` kills the unit, and when it checks whether the unit may accept a self-destruct order.
--- Returning false cancels the kill, unless the unit is a commander outside the playable area. It also rejects the self-destruct order.
--- When a transport is destroyed, each unit attached to it has a 99% chance to be picked for death.
--- A picked unit is killed only if this returns true. The other units are detached.
--- `other` is the destroyed transport for an attached unit, and the unit itself otherwise
---@see moho.entity_methods.Kill # Calls this first
---@see moho.unit_methods.TransportDetachAllUnits # Calls this on attached units when destroying them
---@see moho.unit_methods.CheckCanTakeDamage # Called on a picked commander when this returns false
---@type nil | fun(self: Unit, other: Unit): boolean
Unit.CheckCanBeKilled = nil

--- Called by the engine on a commander attached to a destroyed transport.
--- The engine calls it when the commander was picked for death (99% chance) and its `CheckCanBeKilled` returned false.
--- Returning true deals 10000 damage to the commander instead of killing it. Returning false detaches it unharmed
---@see moho.unit_methods.CheckCanBeKilled
---@type nil | fun(self: Unit, transport: Unit): boolean
Unit.CheckCanTakeDamage = nil

--- Called by the engine when the unit's repair task ends, to clear the enhancement work copied by `InheritWork`.
--- The engine calls it at the end of every repair task, also when the task did not call `InheritWork`
---@see moho.unit_methods.InheritWork
---@type nil | fun(self: Unit)
Unit.ClearWork = nil

--- Called by the engine when the unit is fully reclaimed, to create its wreck. The engine passes 0 as the overkill ratio.
--- If a prop is returned, then the reclaimer continues by reclaiming that prop
---@type nil | fun(self: Unit, overkillRatio: number): Prop | nil
Unit.CreateWreckageProp = nil

--- Called by the engine on a unit in a transport's storage, right before the engine destroys it with the transport
---@see moho.unit_methods.TransportDetachAllUnits
---@see moho.unit_methods.OnAddToStorage # Called when the unit is put into storage
---@type nil | fun(self: Unit)
Unit.DestroyedOnTransport = nil

--- Called by the engine on the capturing unit when it starts a capture: once for the target, then once for each unit attached to the target.
--- Returns the time in seconds, energy cost and mass cost. The engine converts each time to ticks (at least 1), then adds up the results
---@see moho.unit_methods.OnStartCapture
---@type nil | fun(self: Unit, target: Unit): number, number, number
Unit.GetCaptureCosts = nil

--- Called by the engine when the unit starts building a silo missile, tactical or nuclear.
--- Returns the rate the unit builds the missile at.
--- The engine raises a value below 0.1 to 0.1
---@see moho.unit_methods.OnSiloBuildStart
---@type nil | fun(self: Unit): number
Unit.GetEconomyBuildRate = nil

--- Called by the engine when the unit starts building a silo missile, tactical or nuclear.
--- Returns the multiplier for the missile's energy cost
---@type nil | fun(self: Unit): number
Unit.GetEnergyBuildAdjMod = nil

--- Called by the engine when the unit starts building a silo missile, tactical or nuclear.
--- Returns the multiplier for the missile's mass cost
---@type nil | fun(self: Unit): number
Unit.GetMassBuildAdjMod = nil

--- Called by the engine on a mobile builder that starts a structure on a wreck at the exact build position.
--- Only called when the wreck's `AssociatedBP` is in the structure's `Economy.RebuildBonusIds`.
--- Returns the rebuild bonus at full wreck health: the engine multiplies it by the wreck's fraction complete.
--- The engine destroys the wreck when construction starts
---@type nil | fun(self: Unit, blueprint: UnitBlueprint): number
Unit.GetRebuildBonus = nil

--- Called by the engine each tick of reclaiming.
--- Returns the time in seconds, energy and mass to reclaim the target at full health
---@type nil | fun(self: Unit, target: Unit | Prop): number, number, number
Unit.GetReclaimCosts = nil

--- Called by the engine when it creates each weapon of the unit. Returns the Lua class for the weapon.
--- The engine passes the weapon's blueprint label, or its index when the label is empty
---@type nil | fun(self: Unit, label: string | integer): Weapon
Unit.GetWeaponClass = nil

--- Called by the engine when the unit starts repairing a unit in the `Enhancing` state, e.g. when it assists a commander's enhancement
---@see moho.unit_methods.ClearWork
---@type nil | fun(self: Unit, target: Unit)
Unit.InheritWork = nil

--- Called by the engine when the unit is put into a transport's storage
---@see moho.unit_methods.AddUnitToStorage # Puts a unit into storage from Lua
---@see moho.unit_methods.OnRemoveFromStorage # Called when the unit leaves storage
---@see moho.unit_methods.DestroyedOnTransport # Called when the transport is destroyed with the unit in storage
---@type nil | fun(self: Unit, transport: Unit)
Unit.OnAddToStorage = nil

--- Called by the engine on both units when a structure finishes building next to another structure.
--- `adjacentUnit` is the other structure, and `triggerUnit` is the structure that finished building
---@type nil | fun(self: Unit, adjacentUnit: Unit, triggerUnit: Unit)
Unit.OnAdjacentTo = nil

--- Called by the engine when the height of a bone watched by a collision detector drops below 0.1, e.g. a walking unit's foot touching down.
--- The height is measured from the unit's position along the unit's up axis.
--- It fires once per drop, and again only after the bone rose back above 0.1.
--- `x`, `y` and `z` are the bone's offset from the unit's position, in the unit's frame
---@see CreateCollisionDetector
---@see moho.unit_methods.OnAnimTerrainCollision # Called instead when the terrain check is enabled
---@type nil | fun(self: Unit, bone: string, x: number, y: number, z: number)
Unit.OnAnimCollision = nil

--- Called by the engine when a bone watched by a collision detector with the terrain check enabled goes below the terrain or water surface.
--- It fires once per crossing. `x`, `y` and `z` are the bone's world position
---@see moho.CollisionManipulator.EnableTerrainCheck
---@see moho.unit_methods.OnNotAnimTerrainCollision # Called when the bone comes back above the surface
---@type nil | fun(self: Unit, bone: string, x: number, y: number, z: number)
Unit.OnAnimTerrainCollision = nil

--- Called by the engine when the unit's focus entity changes to a new entity
---@type nil | fun(self: Unit)
Unit.OnAssignedFocusEntity = nil

--- Called by the engine when the unit's auto mode is turned off.
--- Auto mode makes a silo build missiles on its own, or a unit assist on its own.
--- The engine calls it on every `SetAutoMode(false)`, even when auto mode was already off.
--- It also calls it before `OnPreCreate` when the blueprint's `AI.InitialAutoMode` is false
---@see moho.unit_methods.SetAutoMode
---@see SetAutoMode # UI version
---@type nil | fun(self: Unit)
Unit.OnAutoModeOff = nil

--- Called by the engine when the unit's auto mode is turned on.
--- Auto mode makes a silo build missiles on its own, or a unit assist on its own.
--- The engine calls it on every `SetAutoMode(true)`, even when auto mode was already on.
--- It also calls it before `OnPreCreate` when the blueprint's `AI.InitialAutoMode` is true
---@see moho.unit_methods.SetAutoMode
---@see SetAutoMode # UI version
---@type nil | fun(self: Unit)
Unit.OnAutoModeOn = nil

--- Called by the engine when a builder's work moves the unit's build progress past 25%, 50% or 75%.
--- The builder's `OnBuildProgress` is called first
---@see moho.unit_methods.OnBuildProgress
---@type nil | fun(self: Unit, builder: Unit, oldProg: number, newProg: number)
Unit.OnBeingBuiltProgress = nil

--- Called by the engine when the unit's work moves its build target's progress past 25%, 50% or 75%.
--- The target's `OnBeingBuiltProgress` follows
---@see moho.unit_methods.OnBeingBuiltProgress
---@type nil | fun(self: Unit, target: Unit, oldProg: number, newProg: number)
Unit.OnBuildProgress = nil

--- Called by the engine when a capture of this unit completes, right after `OnStopBeingCaptured`
---@see moho.unit_methods.OnStopBeingCaptured
---@see moho.unit_methods.OnFailedBeingCaptured # Called instead when the capture ends early
---@type nil | fun(self: Unit, captor: Unit)
Unit.OnCaptured = nil

--- Called by the engine when the unit's resource consumption turns on.
--- `SetConsumptionActive(true)` and the `DebugSetConsumptionActive` console command trigger it.
--- Not called when consumption was already on
---@see moho.unit_methods.SetConsumptionActive
---@type nil | fun(self: Unit)
Unit.OnConsumptionActive = nil

--- Called by the engine when the unit's resource consumption turns off.
--- `SetConsumptionActive(false)` and the `DebugSetConsumptionInActive` console command trigger it.
--- Not called when consumption was already off
---@see moho.unit_methods.SetConsumptionActive
---@type nil | fun(self: Unit)
Unit.OnConsumptionInActive = nil

--- Called by the engine when the unit is created, after `OnPreCreate`.
--- A unit created complete gets `OnStopBeingBuilt` right after this. A unit created to be built gets it when its construction finishes
---@see moho.unit_methods.OnPreCreate
---@see moho.unit_methods.OnStopBeingBuilt
---@type nil | fun(self: Unit)
Unit.OnCreate = nil

--- Called by the engine when the unit takes damage from `Damage` or `DamageArea`, with the index of the instigator's army.
--- Called before `OnDamage`. Not called when the instigator has no army or no damage is left after armor
---@type nil | fun(self: Unit, armyIndex: integer)
Unit.OnDamageBy = nil

--- Called by the engine when an unfinished unit decays to 0 health.
--- An unfinished unit that no builder works on decays: each tick, it loses
--- `0.1 / max(BuildCostEnergy, BuildCostMass, BuildTime)` build progress
--- and the same fraction of its max health
---@type nil | fun(self: Unit)
Unit.OnDecayed = nil

--- Called by the engine when an army creates a new blip for the unit
---@type nil | fun(self: Unit, armyIndex: integer)
Unit.OnDetectedBy = nil

--- Called by the engine when the unit takes >= 2 times as much damage due to armor multi or handicap divisor.
---@type nil | fun(self: Unit, type: DamageType)
Unit.OnExtraDamageDealt = nil

--- Called by the engine when a capture of this unit ends before it completes.
--- This happens when the capture order is cancelled or replaced, or its target changes.
--- Not called when this unit is dead or being destroyed
---@see moho.unit_methods.OnFailedCapture # Called on the captor right after
---@see moho.unit_methods.OnStopBeingCaptured # Called instead when the capture completes
---@type nil | fun(self: Unit, captor: Unit)
Unit.OnFailedBeingCaptured = nil

--- Called by the engine when the unit's capture ends before it completes.
--- This happens when the capture order is cancelled or replaced, or its target changes.
--- Not called when the target is dead or being destroyed
---@see moho.unit_methods.OnFailedBeingCaptured # Called on the target right before
---@see moho.unit_methods.OnStopCapture # Called instead when the capture completes
---@type nil | fun(self: Unit, target: Unit)
Unit.OnFailedCapture = nil

--- Called by the engine when the unit's teleport order ends before the teleport completes, e.g. when the order is cancelled or replaced
---@see moho.unit_methods.OnTeleportUnit
---@type nil | fun(self: Unit)
Unit.OnFailedTeleport = nil

--- Called by the engine when a factory or upgrade build of the unit stops
--- before the unit finished, e.g. when the order is cancelled
---@see moho.unit_methods.OnFailedToBuild # Called on the builder right before
---@see moho.unit_methods.OnStopBeingBuilt # Called instead when the construction finishes
---@type nil | fun(self: Unit)
Unit.OnFailedToBeBuilt = nil

--- Called by the engine when the unit stops building before its target finished
---@see moho.unit_methods.OnStopBuild # Called on both finished and unfinished builds
---@see moho.unit_methods.OnFailedToBeBuilt
---@type nil | fun(self: Unit)
Unit.OnFailedToBuild = nil

--- Called by the engine when the unit gets a ferry order
---@see IssueFerry
---@type nil | fun(self: Unit)
Unit.OnFerryPointSet = nil

--- Called by the engine when the unit was out of fuel and recharges fuel (either by air staging or by landing)
---@type nil | fun(self: Unit)
Unit.OnGotFuel = nil

--- Called by the engine when a dead unit in the `Ballistic` motion state lands, with `"Terrain"` on land and `"Water"` otherwise.
--- A unit falls in that state when:
--- - it is killed while in the air. An air unit killed after landing doesn't fall
--- - it can't fly and is detached from its parent, unless `skipBallistic` is true
--- - `MetaImpact` knocks it into the air
--- A unit that is still alive when it lands is killed if it lands outside the playable area, tilted too far,
--- or where its footprint doesn't fit, and then gets this call. Otherwise it gets no call.
--- A unit attached to another entity doesn't fall, so it gets no call either.
--- Lua also calls it on FAF air units: when their `ShieldCollider` projectile hits terrain or water, and from
--- `OnAnimTerrainCollision` after a shield bounce attaches the unit to that projectile
---@see moho.unit_methods.OnMotionStateChange # Called with `"Ballistic"` when the fall starts, and with `"Crashed"` after this
---@see moho.entity_methods.DetachFrom # Starts the fall of a unit that can't fly
---@see MetaImpact # Knocks units into the air
---@type nil | fun(self: Unit, with: "Terrain" | "Water")
Unit.OnImpact = nil

--- Called by the engine when the unit is killed
---@see moho.entity_methods.Kill
---@see moho.unit_methods.SetDead # Called first
---@type nil | fun(self: Unit, instigator: Unit | Projectile | nil, type: DamageType, overkillRatio: number)
Unit.OnKilled = nil

--- Called by the engine when the horizontal movement state of the unit changes
---@type nil | fun(self: Unit, new: HorizontalMovementState, old: HorizontalMovementState)
Unit.OnMotionHorzEventChange = nil

--- Called by the engine when a unit changes motion state,
--- usually when it attaches/detaches from other entities such as transports.
---@type nil | fun(self: Unit, new: MotionState, old: MotionState)
Unit.OnMotionStateChange = nil

--- Called by the engine when the vertical movement state of the unit changes
---@type nil | fun(self: Unit, new: VerticalMovementState, old: VerticalMovementState)
Unit.OnMotionVertEventChange = nil

--- Called by the engine on both units when one of two adjacent structures is killed or destroyed
---@type nil | fun(self: Unit, adjacentUnit: Unit)
Unit.OnNotAdjacentTo = nil

--- Called by the engine when a bone watched by a collision detector with the terrain check enabled comes back above the terrain or water surface.
--- `x`, `y` and `z` are the bone's world position
---@see moho.unit_methods.OnAnimTerrainCollision
---@type nil | fun(self: Unit, bone: string, x: number, y: number, z: number)
Unit.OnNotAnimTerrainCollision = nil

--- Called by the engine when the unit finishes building any silo missile, right after `OnSiloBuildEnd`.
--- Despite the name, the engine also calls it for tactical missiles
---@see moho.unit_methods.OnSiloBuildEnd
---@type nil | fun(self: Unit, weapon: Weapon)
Unit.OnNukeArmed = nil

--- Called by the engine when the unit executes a nuke order, once the unit's silo has a missile.
--- The order passes the nuke target to the silo weapon. The missile launches later, when the silo weapon fires.
--- Not called for tactical missile orders
---@see IssueNuke
---@type nil | fun(self: Unit)
Unit.OnNukeLaunched = nil

--- Called by the engine when the unit is paused. Not called when the unit was already paused
---@see moho.unit_methods.SetPaused
---@see SetPaused # UI version
---@see IssuePause
---@type nil | fun(self: Unit)
Unit.OnPaused = nil

--- Called by the engine while it creates the unit, before the unit's intel and weapons exist. `OnCreate` follows
---@type nil | fun(self: Unit)
Unit.OnPreCreate = nil

--- Called by the engine when the builder arm of the unit starts aiming at its build target
---@type nil | fun(self: Unit)
Unit.OnPrepareArmToBuild = nil

--- Called by the engine when the unit's resource production turns on.
--- `SetProductionActive(true)` and the `DebugSetProductionActive` console command trigger it.
--- `SetProductionActive` calls it every time, even when production was already on
---@see moho.unit_methods.SetProductionActive
---@type nil | fun(self: Unit)
Unit.OnProductionActive = nil

--- Called by the engine when the unit's resource production turns off.
--- `SetProductionActive(false)` and the `DebugSetProductionInActive` console command trigger it.
--- `SetProductionActive` calls it every time, even when production was already off
---@see moho.unit_methods.SetProductionActive
---@type nil | fun(self: Unit)
Unit.OnProductionInActive = nil

--- Called by the engine when the unit is fully reclaimed
---@see moho.unit_methods.OnStopReclaim # Called on the reclaimer whether or not the reclaim completes
---@type nil | fun(self: Unit, reclaimer: Unit)
Unit.OnReclaimed = nil

--- Called by the engine when the unit is taken out of a transport's storage
---@see moho.unit_methods.OnAddToStorage # Called when the unit is put into storage
---@type nil | fun(self: Unit, transport: Unit)
Unit.OnRemoveFromStorage = nil

--- Called by the engine when the unit runs out of fuel.
---@type nil | fun(self: Unit)
Unit.OnRunOutOfFuel = nil

--- Called by the engine when a script bit of the unit turns off.
--- Only bits in the unit's toggle caps change, and not while the unit is attached to a transport
---@see moho.unit_methods.AddToggleCap
---@see moho.unit_methods.RemoveToggleCap
---@see moho.unit_methods.SetScriptBit
---@see moho.unit_methods.ToggleScriptBit
---@see ToggleScriptBit # UI version
---@type nil | fun(self: Unit, bit: UnitScriptBit)
Unit.OnScriptBitClear = nil

--- Called by the engine when a script bit of the unit turns on.
--- Only bits in the unit's toggle caps change, and not while the unit is attached to a transport
---@see moho.unit_methods.AddToggleCap
---@see moho.unit_methods.RemoveToggleCap
---@see moho.unit_methods.SetScriptBit
---@see moho.unit_methods.ToggleScriptBit
---@see ToggleScriptBit # UI version
---@type nil | fun(self: Unit, bit: UnitScriptBit)
Unit.OnScriptBitSet = nil

--- Called by the engine on a seed unit.
--- When a mobile builder starts a blueprint that has `General.SeedUnit`, it creates the `SeedUnit` blueprint instead.
--- The engine passes the ID of the ordered blueprint, so the seed can turn into that unit, e.g. by upgrading. No FAF unit uses `SeedUnit`
---@type nil | fun(self: Unit, blueprintId: UnitId)
Unit.OnSeedUnitBuilt = nil

--- Called by the engine on a `TELEPORTATION` transport when an unload order makes a unit its teleport beacon, with the beacon's position
---@see IssueTeleportToBeacon
---@see moho.unit_methods.OnTeleportUnit # Called on each cargo unit when it teleports
---@type nil | fun(self: Unit, position: Vector)
Unit.OnSetTeleportDest = nil

--- Called by the engine when the unit finishes building any silo missile, tactical or nuclear
---@see moho.unit_methods.OnNukeArmed # Called right after
---@see moho.unit_methods.OnSiloBuildStart
---@type nil | fun(self: Unit, weapon: Weapon)
Unit.OnSiloBuildEnd = nil

--- Called by the engine when the unit starts building any silo missile, tactical or nuclear
---@see IssueSiloBuildTactical
---@see IssueSiloBuildNuke
---@see moho.unit_methods.OnSiloBuildEnd
---@type nil | fun(self: Unit, weapon: Weapon)
Unit.OnSiloBuildStart = nil

--- Called by the engine when the unit executes a special action order (`UNITCOMMAND_SpecialAction`), with the order's target position.
--- Only the UI issues this order.
--- It comes from the `RULEUCC_SpecialAction` command mode, or from `IssueCommand` or `IssueUnitCommand` with `"SpecialAction"`
---@see IssueCommand
---@see IssueUnitCommand
---@type nil | fun(self: Unit, location: Vector)
Unit.OnSpecialAction = nil

--- Called by the engine when construction of the unit starts
---@type nil | fun(self: Unit, builder: Unit, layer: Layer)
Unit.OnStartBeingBuilt = nil

--- Called by the engine when a unit starts to capture this unit
---@see moho.unit_methods.OnStartCapture # Called on the captor right after
---@type nil | fun(self: Unit, captor: Unit)
Unit.OnStartBeingCaptured = nil

--- Called by the engine when the unit starts building a unit
---@type nil | fun(self: Unit, built: Unit, order: BuildOrderType)
Unit.OnStartBuild = nil

--- Called by the engine when the builder arm of the unit starts tracking its build target
---@type nil | fun(self: Unit)
Unit.OnStartBuilderTracking = nil

--- Called by the engine when the unit starts capturing a target
---@see IssueCapture
---@type nil | fun(self: Unit, target: Unit)
Unit.OnStartCapture = nil

--- Called by the engine when the unit starts reclaiming a target
---@see IssueReclaim
---@type nil | fun(self: Unit, target: Unit | Prop)
Unit.OnStartReclaim = nil

--- Called by the engine when the unit starts refueling at an air staging platform
---@type nil | fun(self: Unit)
Unit.OnStartRefueling = nil

--- Called by the engine when repeat build is turned on. Not called when it was already on
---@see UserUnit.ProcessInfo # `SetRepeatQueue` from the UI
---@see NotifyUpgrade # Copies the setting to the upgraded unit
---@type nil | fun(self: Unit)
Unit.OnStartRepeatQueue = nil

--- Called by the engine when the unit starts sacrificing itself into a target
---@see IssueSacrifice
---@type nil | fun(self: Unit, target: Unit)
Unit.OnStartSacrifice = nil

--- Called by the engine when the unit has reached its transport and starts rising to the transport's attach bone to be loaded
---@see moho.unit_methods.OnStopTransportBeamUp
---@type nil | fun(self: Unit, transport: Unit, bone: Bone)
Unit.OnStartTransportBeamUp = nil

--- Called by the engine when this transport or carrier starts loading units: for a load order, or for a carrier retrieving its units
---@see moho.unit_methods.OnStopTransportLoading
---@type nil | fun(self: Unit)
Unit.OnStartTransportLoading = nil

--- Called by the engine when construction of the unit finishes, or right after `OnCreate` for a unit created complete.
--- `builder` is nil for a unit created complete without a creator
---@see moho.unit_methods.OnFailedToBeBuilt # Called instead when a factory or upgrade build stops early
---@type nil | fun(self: Unit, builder: Unit | nil, layer: Layer)
Unit.OnStopBeingBuilt = nil

--- Called by the engine when a capture of this unit completes, before `OnCaptured`
---@see moho.unit_methods.OnCaptured # Called right after
---@see moho.unit_methods.OnFailedBeingCaptured # Called instead when the capture ends early
---@type nil | fun(self: Unit, captor: Unit)
Unit.OnStopBeingCaptured = nil

--- Called by the engine when the unit stops building or repairing a unit, whether or not the target finished
---@see moho.unit_methods.OnFailedToBuild # Also called when the target did not finish
---@type nil | fun(self: Unit, built: Unit, order: BuildOrderType)
Unit.OnStopBuild = nil

--- Called by the engine when the builder arm of the unit stops tracking its build target
---@type nil | fun(self: Unit)
Unit.OnStopBuilderTracking = nil

--- Called by the engine when the unit completes capturing its target, before the target's `OnStopBeingCaptured` and `OnCaptured`.
--- Also called when the target is gone or can't be captured, with the unit itself as `target`
---@see moho.unit_methods.OnFailedCapture # Called instead when the capture ends early
---@type nil | fun(self: Unit, target: Unit)
Unit.OnStopCapture = nil

--- Called by the engine when the unit stops reclaiming a target, whether or not the target was fully reclaimed
---@see moho.unit_methods.OnReclaimed # Called on a fully reclaimed target
---@type nil | fun(self: Unit, target: Unit | Prop)
Unit.OnStopReclaim = nil

--- Called by the engine when repeat build is turned off. Not called when it was already off
---@see UserUnit.ProcessInfo # `SetRepeatQueue` from the UI
---@see NotifyUpgrade # Copies the setting to the upgraded unit
---@type nil | fun(self: Unit)
Unit.OnStopRepeatQueue = nil

--- Called by the engine when the unit completes sacrificing itself into a target, after the target received the sacrifice resources
---@type nil | fun(self: Unit, target: Unit)
Unit.OnStopSacrifice = nil

--- Called by the engine when the unit stops rising into its transport: it reached the attach bone, or the load was interrupted
---@see moho.unit_methods.OnStartTransportBeamUp
---@type nil | fun(self: Unit)
Unit.OnStopTransportBeamUp = nil

--- Called by the engine when this transport or carrier stops loading units, whether or not all units were loaded
---@see moho.unit_methods.OnTransportAborted # Called after this when the load order ended before all units were loaded
---@type nil | fun(self: Unit)
Unit.OnStopTransportLoading = nil

--- Called by the engine when the unit starts a teleport order, with the destination and orientation.
--- The engine doesn't move the unit: Lua charges the teleport, then moves it with `Warp`.
--- For cargo of a `TELEPORTATION` transport, `teleporter` is the transport and `location` the beacon's position
---@see IssueTeleport
---@see Warp
---@see moho.unit_methods.OnFailedTeleport # Called when the order ends before the teleport completes
---@type nil | fun(self: Unit, teleporter: Unit, location: Vector, orientation: Quaternion)
Unit.OnTeleportUnit = nil

--- Called by the engine when the terrain type under the unit changes
---@type nil | fun(self: Unit, new: TerrainType, old: TerrainType)
Unit.OnTerrainTypeChange = nil

--- Called by the engine when the transport ends a load order before all units are loaded
---@type nil | fun(self: Unit)
Unit.OnTransportAborted = nil

--- Called by the engine when a unit attaches to the transport
---@type nil | fun(self: Unit, attachBone: Bone, attachedUnit: Unit)
Unit.OnTransportAttach = nil

--- Called by the engine when a unit detaches from the transport
---@type nil | fun(self: Unit, attachBone: Bone, detachedUnit: Unit)
Unit.OnTransportDetach = nil

--- Called by the engine when the transport starts a load order
---@see IssueTransportLoad
---@type nil | fun(self: Unit)
Unit.OnTransportOrdered = nil

--- Called by the engine when the transport can't carry a unit that was ordered into it
---@type nil | fun(self: Unit)
Unit.OnTransportReject = nil

--- Called by the engine when the unit is unpaused. Not called when the unit was already unpaused
---@see moho.unit_methods.SetPaused
---@see SetPaused # UI version
---@type nil | fun(self: Unit)
Unit.OnUnpaused = nil

--- Called by the engine when the unit dies, to set `Dead`. `Kill` calls it first, before `OnKilled`.
--- For a unit destroyed without `Kill`, the engine calls it when it processes the destruction at the end of the tick, before `OnDestroy`.
--- `BeenDestroyed` becomes true earlier, at the `Destroy` call
---@see moho.entity_methods.Kill
---@see moho.entity_methods.BeenDestroyed
---@type nil | fun(self: Unit)
Unit.SetDead = nil

--- Called by the engine when deciding whether to repair or guard a shield unit. Returns true if its shield is on
---@type nil | fun(self: Unit): boolean
Unit.ShieldIsOn = nil

-- Added by FA-Binary-Patches

--- Introduced by https://github.com/FAForever/FA-Binary-Patches/pull/22
---@class UnitCommand
---@field blueprintId? string -- For build commands
---@field commandType integer -- Integer representation of CommandType, see UnitQueueDataToCommand for details
---@field targetId? EntityId
---@field x number -- X coordinate of command target
---@field y number -- Y coordinate of command target
---@field z number -- Z coordinate of command target

-- Changed by FA-Binary-Patches

--- Called by the engine when the turning state of an air unit changes.
--- Disabled by https://github.com/FAForever/FA-Binary-Patches/commit/e23e4ea9ad1aeed74b718aaf27eff6bd28742b95
---@type nil | fun(self: Unit, new: "Straight" | "Turn" | "SharpTurn", old: "Straight" | "Turn" | "SharpTurn")
Unit.OnMotionTurnEventChange = nil

return Unit

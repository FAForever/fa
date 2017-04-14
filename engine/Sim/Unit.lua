--- Class Unit
-- @classmod Sim.Unit

---
--  unit:AddCommandCap(capName) -- Add a command cap to a unit.
function Unit:AddCommandCap(capName)
end

---
--  unit:AddToggleCap(capName) -- Add a toggle cap to a unit.
function Unit:AddToggleCap(capName)
end

---
--  Unit:AddUnitToStorage(storedUnit)
function Unit:AddUnitToStorage(storedUnit)
end

---
--  Unit:AlterArmor(damageTypeName, multiplier)
function Unit:AlterArmor(damageTypeName,  multiplier)
end

---
--  Calculate the desired world position from the supplied relative vector from the center of the unit
function Unit:CalculateWorldPositionFromRelative()
end

---
--  CanBuild(self, blueprint
function Unit:CanBuild()
end

---
--  See if the unit can path to the goal
function Unit:CanPathTo()
end

---
--  See if the unit can path to the goal rectangle
function Unit:CanPathToRect()
end

---
--  ClearFocusEntity(self)
function Unit:ClearFocusEntity(self)
end

---
--  Unit:EnableManipulators([string boneName | int boneIndex], bool Enable)
function Unit:EnableManipulators([string boneName | int boneIndex],  bool Enable)
end

---
--  mult = Unit:GetArmorMult(damageTypeName)
function Unit:GetArmorMult(damageTypeName)
end

---
--  GetAttacker() - get the tactical attack manager object of this unit
function Unit:GetAttacker()
end

---
--  blip = GetBlip(armyIndex) - returns a blip (if any) that the given army has for the unit
function Unit:GetBlip(armyIndex)
end

---
--  unit:GetBuildRate() -- returns the build rate of a unit: what fraction of target unit it builds per second.
function Unit:GetBuildRate()
end

---
--  GetCargo(self)
function Unit:GetCargo(self)
end

---
--  Unit:GetCommandQueue()
function Unit:GetCommandQueue()
end

---
--  Get the consumption of energy of the unit
function Unit:GetConsumptionPerSecondEnergy()
end

---
--  Get the consumption of mass of the unit
function Unit:GetConsumptionPerSecondMass()
end

---
--  GetUnitId(self)
function Unit:GetCurrentLayer()
end

---
--  Unit:GetCurrentMoveLocation()
function Unit:GetCurrentMoveLocation()
end

---
--  Get the fire state for the unit
function Unit:GetFireState()
end

---
--  GetFocusUnit(self)
function Unit:GetFocusUnit(self)
end

---
--  Get the fuel ratio
function Unit:GetFuelRatio()
end

---
--  Get the fuel use time
function Unit:GetFuelUseTime()
end

---
--  Unit:GetGuardedUnit()
function Unit:GetGuardedUnit()
end

---
--  Unit:GetGuards()
function Unit:GetGuards()
end

---
--  GetHealth(self)
function Unit:GetHealth(self)
end

---
--  GetNavigator() - get the navigator object of this unit
function Unit:GetNavigator()
end

---
--  Unit:GetNukeSiloAmmoCount()
function Unit:GetNukeSiloAmmoCount()
end

---
--  Get number of factory/engineer build orders that fit in the specified category
function Unit:GetNumBuildOrders()
end

---
--  Get the production of energy of the unit
function Unit:GetProductionPerSecondEnergy()
end

---
--  Get the production of mass of the unit
function Unit:GetProductionPerSecondMass()
end

---
--  Get the rally point for the factory
function Unit:GetRallyPoint()
end

---
--  Return the fraction of requested resources this unit consumed last tick. Normally 1, but can be fractional if economy is struggling.
function Unit:GetResourceConsumed()
end

---
--  Get the current toggle state of the script bit that matches the string
function Unit:GetScriptBit()
end

---
--  Get the shield ratio
function Unit:GetShieldRatio()
end

---
--  GetStat(Name[,defaultVal])
function Unit:GetStat(Name[, defaultVal])
end

---
--  Unit:GetTacticalSiloAmmoCount()
function Unit:GetTacticalSiloAmmoCount()
end

---
--  Return our target unit if we have one
function Unit:GetTargetEntity()
end

---
--  Unit:GetTransportFerryBeacon()
function Unit:GetTransportFerryBeacon()
end

---
--  GetUnitId(self)
function Unit:GetUnitId(self)
end

---
--  GetVelocity() -> x,y,z
function Unit:GetVelocity()
end

---
--  GetWeapon(self,index) -- return the index'th weapon of this unit. Index must be between 1 and self:GetWeaponCount(), inclusive.
function Unit:GetWeapon(self, index)
end

---
--  GetWeaponCount(self) -- return the number of weapons on this unit. Note that dummy weapons are not included in the count, so this may differ from the number of weapons defined in the unit's blueprint.
function Unit:GetWeaponCount(self)
end

---
--  GetWorkProgress()
function Unit:GetWorkProgress()
end

---
--  Unit:GiveNukeSiloAmmo(num)
function Unit:GiveNukeSiloAmmo(num)
end

---
--  Unit:GiveTacticalSiloAmmo(num)
function Unit:GiveTacticalSiloAmmo(num)
end

---
--  Unit:HasMeleeSpaceAroundTarget(target)
function Unit:HasMeleeSpaceAroundTarget(target)
end

---
--  Unit:HasValidTeleportDest()
function Unit:HasValidTeleportDest()
end

---
--  HideBone(self,bone,affectChildren)
function Unit:HideBone(self, bone, affectChildren)
end

---
--  Unit:IsBeingBuilt()
function Unit:IsBeingBuilt()
end

---
--  Returns if this unit can be captured or not
function Unit:IsCapturable()
end

---
--  IsIdleState(unit)
function Unit:IsIdleState(unit)
end

---
--  bool IsMobile() - Is this a mobile unit?
function Unit:IsMobile()
end

---
--  bool IsMoving() - Is this unit moving?
function Unit:IsMoving()
end

---
--  Returns if this unit has its overcharge paused
function Unit:IsOverchargePaused()
end

---
--  Unit:IsPaused()
function Unit:IsPaused()
end

---
--  IsStunned(unit)
function Unit:IsStunned(unit)
end

---
--  IsUnitState(unit, stateName)
function Unit:IsUnitState(unit,  stateName)
end

---
--  bool = IsValidTarget(self)
function Unit:IsValidTarget(self)
end

---
--  Kill a specific manipulator held by a script object
function Unit:KillManipulator()
end

---
--  Unit:KillManipulators([boneName|boneIndex])
function Unit:KillManipulators([boneName|boneIndex])
end

---
--  Unit:MeleeWarpAdjacentToTarget(target)
function Unit:MeleeWarpAdjacentToTarget(target)
end

---
--  Unit:PrintCommandQueue()
function Unit:PrintCommandQueue()
end

---
--  RecoilImpulse(self, x, y, z)
function Unit:RecoilImpulse(self,  x,  y,  z)
end

---
--  Allow building of categories for this unit
function Unit:RemoveBuildRestriction()
end

---
--  unit:RemoveCommandCap(capName) -- Remove a command cap to a unit.
function Unit:RemoveCommandCap(capName)
end

---
--  Unit:RemoveNukeSiloAmmo(num)
function Unit:RemoveNukeSiloAmmo(num)
end

---
--  Unit:RemoveTacticalSiloAmmo(num)
function Unit:RemoveTacticalSiloAmmo(num)
end

---
--  unit:RemoveToggleCap(capName) -- Remove a toggle cap to a unit.
function Unit:RemoveToggleCap(capName)
end

---
--  Restore buildable categories to that as defined in the blueprint
function Unit:RestoreBuildRestrictions()
end

---
--  Restore the command caps of the unit back to blueprint spec.
function Unit:RestoreCommandCaps()
end

---
--  Restore the toggle caps of the unit back to blueprint spec.
function Unit:RestoreToggleCaps()
end

---
--  Revert the collision shape to the blueprint spec
function Unit:RevertCollisionShape()
end

---
--  Revert the elevation of the unit back to the blueperint spec
function Unit:RevertElevation()
end

---
--  Restore regen rate of the unit back to blueprint spec.
function Unit:RevertRegenRate()
end

---
--  ScaleGetBuiltEmitter(self, emitter)
function Unit:ScaleGetBuiltEmitter(self,  emitter)
end

---
--  Set the acceleration multiplier of the unit
function Unit:SetAccMult()
end

---
--  Set auto silo build mode to on/off
function Unit:SetAutoMode()
end

---
--  SetBlockCommandQueue(unit, flag)
function Unit:SetBlockCommandQueue(unit,  flag)
end

---
--  Set the break off distance multiplier of the unit
function Unit:SetBreakOffDistanceMult()
end

---
--  Set the break off trigger multiplier of the unit
function Unit:SetBreakOffTriggerMult()
end

---
--  unit:SetBuildRate(frac) -- Set the build rate of a unit: what fraction of target unit it builds per second.
function Unit:SetBuildRate(frac)
end

---
--  SetBusy(unit, flag)
function Unit:SetBusy(unit,  flag)
end

---
--  Set if this unit can be captured or not.
function Unit:SetCapturable()
end

---
--  Unit:SetConsumptionActive(flag)
function Unit:SetConsumptionActive(flag)
end

---
--  unit:SetConsumptionPerSecondEnergy(value) -- Set the consumption of energy of a unit
function Unit:SetConsumptionPerSecondEnergy(value)
end

---
--  Set the consumption of mass of the unit
function Unit:SetConsumptionPerSecondMass()
end

---
--  Set the creator for this unit
function Unit:SetCreator()
end

---
--  Unit:SetCustomName(name)
function Unit:SetCustomName(name)
end

---
--  SetDoNotTarget(unit, flag)
function Unit:SetDoNotTarget(unit,  flag)
end

---
--  Set the elevation of the unit
function Unit:SetElevation()
end

---
--  Set a specific fire state for the retaliation state of the unit
function Unit:SetFireState()
end

---
--  SetFocusUnit(self, focus)
function Unit:SetFocusEntity()
end

---
--  Set the fuel ratio
function Unit:SetFuelRatio()
end

---
--  Set the fuel use time
function Unit:SetFuelUseTime()
end

---
--  SetImmobile(unit, flag)
function Unit:SetImmobile(unit,  flag)
end

---
--  SetIsValidTarget(self,bool)
function Unit:SetIsValidTarget(self, bool)
end

---
--  Set if this unit has an overcharge pasued.
function Unit:SetOverchargePaused()
end

---
--  Unit:SetPaused()
function Unit:SetPaused()
end

---
--  Unit:SetProductionActive(flag)
function Unit:SetProductionActive(flag)
end

---
--  Set the production of energy of the unit
function Unit:SetProductionPerSecondEnergy()
end

---
--  Set the production of mass of the unit
function Unit:SetProductionPerSecondMass()
end

---
--  Set if this unit can be reclaimed or not.
function Unit:SetReclaimable()
end

---
--  unit:SetRegenRate(rate) -- Set the regen rate of a unit.
function Unit:SetRegenRate(rate)
end

---
--  Set the script bit that matches the string to the desired state
function Unit:SetScriptBit()
end

---
--  Set the shield ratio
function Unit:SetShieldRatio()
end

---
--  Set the speed multiplier of the unit
function Unit:SetSpeedMult()
end

---
--  SetStat(Name, Value)
function Unit:SetStat(Name,  Value)
end

---
--  SetStrategicUnderlay(icon)
function Unit:SetStrategicUnderlay(icon)
end

---
--  SetStunned(unit, time)
function Unit:SetStunned(unit,  time)
end

---
--  Set the turn multiplier of the unit
function Unit:SetTurnMult()
end

---
--  SetUnSelectable(unit, flag)
function Unit:SetUnSelectable(unit,  flag)
end

---
--  SetUnitState(name, bool)
function Unit:SetUnitState(name,  bool)
end

---
--  SetWorkProgress(float)
function Unit:SetWorkProgress(float)
end

---
--  ShowBone(self,bone,affectChildren)
function Unit:ShowBone(self, bone, affectChildren)
end

---
--  StopSiloBuild(unit)
function Unit:StopSiloBuild(unit)
end

---
--  Test if a unit has this specified set to true in the blueprint spec.
function Unit:TestCommandCaps()
end

---
--  Test if a unit has this specified set to true in the blueprint spec.
function Unit:TestToggleCaps()
end

---
--  Toggle the fire state for the retaliation state of the unit
function Unit:ToggleFireState()
end

---
--  Toggle the script bit that matches the string
function Unit:ToggleScriptBit()
end

---
--  DetachAllUnits(self,destroySomeUnits)
function Unit:TransportDetachAllUnits()
end

---
--  TransportHasAvailableStorage(self)
function Unit:TransportHasAvailableStorage(self)
end

---
--  TransportHasSpaceFor(self,target)
function Unit:TransportHasSpaceFor(self, target)
end

---
--  derived from Entity
function Unit:base()
end

---
--
function Unit:moho.unit_methods()
end


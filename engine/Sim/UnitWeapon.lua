---@meta

-- Engine internal states for Tactical/Nuke fire tasks:
-- State 0: Check range
-- Move the unit within min/max range.
-- Then go to State 1 if we need ammo or State 2 if we don't.
-- State 1: Building ammo
-- Checks every 10 ticks if ammo is loaded, afterwards transitioning to State 2.
-- State 2: Waiting to fire
-- If unit not busy, give a fire command and increment State. Always waits 3 ticks afterwards.
-- State 3: Firing
-- Check if unit busy, in which case increment State. Always waits 3 ticks afterwards.
-- State 4: Finished firing
-- If unit not busy, end the task, otherwise wait 3 ticks.

-- Only weapons with `ManualFire = true` and `OverChargeWeapon = false` in their blueprint can be used for tactical/nuke fire orders.

---@class moho.weapon_methods
local UnitWeapon = {}

--- Returns whether the weapon has been destroyed, like `IsDestroyed`. Weapons are destroyed with
--- their unit at the end of the tick
---@return boolean
function UnitWeapon:BeenDestroyed()
end

--- `UnitWeapon:CanFire` calls this engine `CanFire` function that is used in the firing cycle, alongside
--- the self-explanatory `HasTarget`, `HasSiloAmmo`, and `TargetSolutionStatusGun() == TRS_Available` calls.
---
--- Lua pseudocode describing the engine `CanFire` function's logic.
--- Underscore prefixes indicate engine fields/functions.
--[[
if
    !unit:IsStunned()
    and !unit:IsUnitState("Busy")
    and !unit.Blueprint.Air.CanFly or unit.Layer == "Air"
    and !unit.Blueprint.AI.NeedUnpack or unit:IsUnitState("Immobile")
    and weapon:_CheckWaterDepthFiringRestrictions()
then
    if !unit.Blueprint.Air.Winged then 
        return weapon._AimOnTarget -- aim on target in terms of firing tolerance
    end 
    if !weapon.Blueprint.AutoInitiateAttackCommand 
      or unit:_GetSpeed() >= 0.25 * unit.Blueprint.MaxAirSpeed * unit._SpeedMult
    then
        if !weapon.Blueprint.NeedToComputeBombDrop or !weapon:_HasTarget() then 
            return weapon._AimOnTarget 
        end
        if unit:IsUnitState("MakingAttackRun") then
            -- Involves weapon BombDropThreshold and unit PredictAheadForBombDrop
            if weapon:_UnitIsInBombDropZone() then
                return weapon._AimOnTarget 
            end 
        end
    end
end
return false
]]

--- Returns true if the weapon has a target and it can fire at it, identical to the engine's firing conditions.
---
--- This includes having a target, ammo, a firing solution for the target, aiming within firing tolerance, unit
--- not being busy or stunned, and a list of other conditions based on blueprint values.
---@return boolean
function UnitWeapon:CanFire()
end

--- Sets the engine weapon attribute, but it doesn't seem to be used anywhere.
---@deprecated # Non-functional, use Lua function instead.
---@see Weapon.AddDamageMod # Use instead
---@param damage number
function UnitWeapon:ChangeDamage(damage)
end

--- Sets the engine weapon attribute, but it doesn't seem to be used anywhere.
---@deprecated # Non-functional, use Lua function instead.
---@see Weapon.AddDamageRadiusMod # Use instead
---@param radius number
function UnitWeapon:ChangeDamageRadius(radius)
end

--- Sets the engine weapon attribute, but it doesn't seem to be used anywhere.
---@deprecated # Non-functional, use Lua function instead.
---@see Weapon.ChangeDamageType # Use instead
---@param typeName DamageType
function UnitWeapon:ChangeDamageType(typeName)
end

---
---@param tolerance number
function UnitWeapon:ChangeFiringTolerance(tolerance)
end

---
---@param max number
function UnitWeapon:ChangeMaxHeightDiff(max)
end

---
---@param maxRadius number
function UnitWeapon:ChangeMaxRadius(maxRadius)
end

---
---@param minRadius number
function UnitWeapon:ChangeMinRadius(minRadius)
end

--- Changes the projectile blueprint of a weapon
---@param projBp BlueprintId
function UnitWeapon:ChangeProjectileBlueprint(projBp)
end

---
---@param value number
function UnitWeapon:ChangeRateOfFire(value)
end

---
---@param muzzlebone Bone
---@return Projectile
function UnitWeapon:CreateProjectile(muzzlebone)
end

---
---@param bone Bone
---@param r number
---@param g number
---@param b number
---@param glow number
---@param width number
---@param texture string
---@param lifetime number
function UnitWeapon:DoInstaHit(bone, r, g, b, glow, width, texture, lifetime)
end

---
---@see moho.weapon_methods.OnFire # Called when it fires
---@return boolean
function UnitWeapon:FireWeapon()
end

---
---@return WeaponBlueprint
function UnitWeapon:GetBlueprint()
end

---
---@return Blip | Unit | nil
function UnitWeapon:GetCurrentTarget()
end

---
---@return Vector
function UnitWeapon:GetCurrentTargetPos()
end

--- Returns the progress of the engine's firing clock determined by RateOfFire, usually from the blueprint
---@see ChangeRateOfFire
---@return number # within [0.0, 1.0]
function UnitWeapon:GetFireClockPct()
end

--- Gets the firing randomness
---@return number
function UnitWeapon:GetFiringRandomness()
end

---
---@return ProjectileBlueprint
function UnitWeapon:GetProjectileBlueprint()
end

--- Returns true if the given AimManipulator is the weapon's fire control
---@see SetFireControl
---@param label string label that was used to create the AimManipulator
---@return boolean
function UnitWeapon:IsFireControl(label)
end

---
---@param params SoundHandle
function UnitWeapon:PlaySound(params)
end

--- Force the weapon to recheck its targets. Also resets the counter for AttackGroundTries
---@see moho.weapon_methods.OnLostTarget # Called when the weapon had a target
function UnitWeapon:ResetTarget()
end

---
---@param enabled boolean
function UnitWeapon:SetEnabled(enabled)
end

--- Set the AimManipulator for which `OnFire` will be called when its
--- *defined* yaw/pitch bones are on target (within the firing tolerance).  
--- Defaults to the first aim controller that was created for the weapon.
---@param label string # label that was used to create the AimManipulator
function UnitWeapon:SetFireControl(label)
end

---
---@param mask string
function UnitWeapon:SetFireTargetLayerCaps(mask)
end

---
---@param randomness number
function UnitWeapon:SetFiringRandomness(randomness)
end

---
---@see moho.weapon_methods.OnGotTarget # Called when the weapon had no target
---@param entity Entity | Unit
function UnitWeapon:SetTargetEntity(entity)
end

---
---@see moho.weapon_methods.OnGotTarget # Called when the weapon had no target
---@param location Vector
function UnitWeapon:SetTargetGround(location)
end

--- Sets the targeting priorities for the unit
---@param priorities EntityCategory[]
function UnitWeapon:SetTargetingPriorities(priorities)
end

--- Transfers target from this weapon to another.  
--- The other weapon may still change targets automatically afterwards.
---@see moho.weapon_methods.OnGotTarget # Called on the other weapon when it had no target
---@see moho.weapon_methods.OnLostTarget # Called on the other weapon when the target is empty
---@param otherWeapon Weapon
function UnitWeapon:TransferTarget(otherWeapon)
end

--- Returns true if the weapon currently has a target.
--- This only updates at the end of a tick, so it shouldn't be used in behavior relating to OnLostTarget or OnGotTarget callbacks
---@return boolean
function UnitWeapon:WeaponHasTarget()
end

--- Called by the engine during an overcharge attack order, to check if the weapon may fire.
--- Returning false makes the order wait before checking again
---@see IssueOverCharge # Overcharge attack order
---@type nil | fun(self: Weapon): boolean
UnitWeapon.CanWeaponFire = nil

--- Called by the engine after the weapon is constructed
---@type nil | fun(self: Weapon)
UnitWeapon.OnCreate = nil

--- Called by the engine when the unit's weapons are destroyed
---@type nil | fun(self: Weapon)
UnitWeapon.OnDestroy = nil

--- Called by the engine on the overcharge weapon when an overcharge attack order ends
---@see IssueOverCharge # Overcharge attack order
---@type nil | fun(self: Weapon)
UnitWeapon.OnDisableWeapon = nil

--- Called by the engine on the overcharge weapon when an overcharge attack order starts
---@see IssueOverCharge # Overcharge attack order
---@type nil | fun(self: Weapon)
UnitWeapon.OnEnableWeapon = nil

--- Called by the engine when the weapon fires, and by `FireWeapon`
---@see moho.weapon_methods.FireWeapon # Fires the weapon
---@type nil | fun(self: Weapon)
UnitWeapon.OnFire = nil

--- Called by the engine when the weapon gets a target while it had none.
--- Switching from one target to another calls neither this nor `OnLostTarget`
---@see moho.weapon_methods.SetTargetEntity # Sets a target
---@see moho.weapon_methods.SetTargetGround # Sets a target
---@see moho.weapon_methods.TransferTarget # Sets the target of another weapon
---@type nil | fun(self: Weapon)
UnitWeapon.OnGotTarget = nil

--- Called by the engine on each weapon of the unit when its attack-ground order changes, such as when the player moves the order.
--- The engine clears the unit's desired target after this
---@type nil | fun(self: Weapon)
UnitWeapon.OnHaltFire = nil

--- Called by the engine when the weapon loses its target and has none left
---@see moho.weapon_methods.ResetTarget # Clears the target
---@see moho.weapon_methods.TransferTarget # Sets the target of another weapon
---@type nil | fun(self: Weapon)
UnitWeapon.OnLostTarget = nil

--- Called by the engine when the heading (yaw) bone of an aim manipulator of the weapon starts turning, toward a target or back to its rest pose.
--- It counts as turning while it turns more than 0.001 radians in a tick. Pitch changes don't count.
--- Not called again until `OnStopTracking`, so a turret that follows a moving target without pausing gets one call
---@type nil | fun(self: Weapon, label: string)
UnitWeapon.OnStartTracking = nil

--- Called by the engine when the heading (yaw) bone of an aim manipulator of the weapon stops turning, after `OnStartTracking`.
--- It stops when it turns 0.001 radians or less in a tick, such as when it reaches the target heading
---@type nil | fun(self: Weapon, label: string)
UnitWeapon.OnStopTracking = nil

return UnitWeapon

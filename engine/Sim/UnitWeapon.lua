---@meta

---@class moho.weapon_methods
local UnitWeapon = {}

---
---@return boolean
function UnitWeapon:BeenDestroyed()
end

--- Returns true if the weapon is aiming at the target as allowed by the FiringTolerance blueprint value and the target is within the weapon's range
---@return boolean
function UnitWeapon:CanFire()
end

---
---@param damage number
function UnitWeapon:ChangeDamage(damage)
end

---
---@param radius number
function UnitWeapon:ChangeDamageRadius(radius)
end

---
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
---@return boolean
function UnitWeapon:FireWeapon()
end

---
---@return WeaponBlueprint
function UnitWeapon:GetBlueprint()
end

---
---@return Blip | Unit | Projectile | nil
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
---@param entity Entity | Unit
function UnitWeapon:SetTargetEntity(entity)
end

---
---@param location Vector
function UnitWeapon:SetTargetGround(location)
end

--- Sets the targeting priorities for the unit
---@param priorities EntityCategory[]
function UnitWeapon:SetTargetingPriorities(priorities)
end

--- Transfers target from this weapon to another.  
--- The other weapon may still change targets automatically afterwards.
---@param otherWeapon Weapon
function UnitWeapon:TransferTarget(otherWeapon)
end

--- Returns true if the weapon currently has a target.
--- This only updates at the end of a tick, so it shouldn't be used in behavior relating to OnLostTarget or OnGotTarget callbacks
---@return boolean
function UnitWeapon:WeaponHasTarget()
end

return UnitWeapon

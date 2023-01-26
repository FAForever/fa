---@meta

---@class moho.weapon_methods
local UnitWeapon = {}

---
---@return boolean
function UnitWeapon:BeenDestroyed()
end

---
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
---@param projBp ProjectileBlueprint
function UnitWeapon:ChangeProjectileBlueprint(projBp)
end

---
---@param value number
function UnitWeapon:ChangeRateOfFire(value)
end

---
---@param muzzlebone Bone
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
---@return Blip | Unit | nil
function UnitWeapon:GetCurrentTarget()
end

---
---@return Vector
function UnitWeapon:GetCurrentTargetPos()
end

--- Gets the firing clock percent, `0.0` - `1.0`
---@return number
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

---
---@param label string
---@return boolean
function UnitWeapon:IsFireControl(label)
end

---
---@param params SoundHandle
function UnitWeapon:PlaySound(params)
end

---
function UnitWeapon:ResetTarget()
end

---
---@param enabled boolean
function UnitWeapon:SetEnabled(enabled)
end

---
---@param label string
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

--- Transfers target from one weapon to another
function UnitWeapon:TransferTarget()
end

---
---@return boolean
function UnitWeapon:WeaponHasTarget()
end

return UnitWeapon

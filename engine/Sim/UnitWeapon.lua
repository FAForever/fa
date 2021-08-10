--- Class UnitWeapon
-- @classmod Sim.UnitWeapon

---
--  UnitWeapon:CanFire()
function UnitWeapon:CanFire()
end

---
--  UnitWeapon:ChangeDamage(value)
function UnitWeapon:ChangeDamage(value)
end

---
--  UnitWeapon:ChangeDamageRadius(value)
function UnitWeapon:ChangeDamageRadius(value)
end

---
--  UnitWeapon:ChangeDamageType(typeName)
function UnitWeapon:ChangeDamageType(typeName)
end

---
--  UnitWeapon:ChangeFiringTolerance(value)
function UnitWeapon:ChangeFiringTolerance(value)
end

---
--  UnitWeapon:ChangeMaxHeightDiff(value)
function UnitWeapon:ChangeMaxHeightDiff(value)
end

---
--  UnitWeapon:ChangeMaxRadius(value)
function UnitWeapon:ChangeMaxRadius(value)
end

---
--  UnitWeapon:ChangeMinRadius(value)
function UnitWeapon:ChangeMinRadius(value)
end

---
--  Change the projectile blueprint of a weapon
function UnitWeapon:ChangeProjectileBlueprint()
end

---
--  UnitWeapon:ChangeRateOfFire(value)
function UnitWeapon:ChangeRateOfFire(value)
end

---
--  UnitWeapon:CreateProjectile(muzzlebone)
function UnitWeapon:CreateProjectile(muzzlebone)
end

---
--  UnitWeapon:DoInstaHit(bone, r,g,b, glow, width, texture, lifetime)
function UnitWeapon:DoInstaHit(bone,  r, g, b,  glow,  width,  texture,  lifetime)
end

---
--  bool = UnitWeapon:FireWeapon()
function UnitWeapon:FireWeapon()
end

---
--  blueprint = UnitWeapon.Blueprint
function UnitWeapon.Blueprint
end

---
--  UnitWeapon:GetCurrentTarget()
function UnitWeapon:GetCurrentTarget()
end

---
--  UnitWeapon:GetCurrentTargetPos()
function UnitWeapon:GetCurrentTargetPos()
end

---
--  Get the firing clock percent (0 - 1)
function UnitWeapon:GetFireClockPct()
end

---
--  Get the firing randomness
function UnitWeapon:GetFiringRandomness()
end

---
--  blueprint = UnitWeapon:GetProjectileBlueprint()
function UnitWeapon:GetProjectileBlueprint()
end

---
--  UnitWeapon:IsFireControl(label)
function UnitWeapon:IsFireControl(label)
end

---
--  UnitWeapon:PlaySound(weapon,ParamTable)
function UnitWeapon:PlaySound(weapon, ParamTable)
end

---
--  UnitWeapon:ResetTarget()
function UnitWeapon:ResetTarget()
end

---
--  UnitWeapon:SetEnabled(enabled)
function UnitWeapon:SetEnabled(enabled)
end

---
--  UnitWeapon:SetFireControl(label)
function UnitWeapon:SetFireControl(label)
end

---
--  UnitWeapon:SetFireTargetLayerCaps(mask)
function UnitWeapon:SetFireTargetLayerCaps(mask)
end

---
--  Set the firing randomness
function UnitWeapon:SetFiringRandomness()
end

---
--  UnitWeapon:SetTarget(entity)
function UnitWeapon:SetTargetEntity()
end

---
--  UnitWeapon:SetTarget(location)
function UnitWeapon:SetTargetGround()
end

---
--  Set the targeting priorities for the unit
function UnitWeapon:SetTargetingPriorities()
end

---
--  Transfer target from 1 weapon to another
function UnitWeapon:TransferTarget()
end

---
--  bool = UnitWeapon:HasTarget()
function UnitWeapon:WeaponHasTarget()
end

---
--
function UnitWeapon:moho.weapon_methods()
end


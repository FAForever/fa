local TRailGunProjectile = import("/lua/terranprojectiles.lua").TRailGunProjectile

-- Terran Anti Air basic projectile
---@class TAARailgun02 : TRailGunProjectile
TAARailgun02 = ClassProjectile(TRailGunProjectile) { 
    FxTrails = import("/lua/effecttemplates.lua").NoEffects,
}
TypeClass = TAARailgun02
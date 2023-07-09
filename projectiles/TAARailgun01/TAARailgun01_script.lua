local TRailGunProjectile = import("/lua/terranprojectiles.lua").TRailGunProjectile

-- Terran Anti Air basic projectile
---@class TAARailgun01 : TRailGunProjectile
TAARailgun01 = ClassProjectile(TRailGunProjectile) {
    FxTrails = import("/lua/effecttemplates.lua").NoEffects,
}
TypeClass = TAARailgun01
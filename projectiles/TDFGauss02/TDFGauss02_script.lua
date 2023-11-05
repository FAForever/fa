local TDFGaussCannonProjectile = import("/lua/terranprojectiles.lua").TDFMediumLandGaussCannonProjectile

-- Terran Gauss Cannon Projectile
---@class TDFGauss02: TDFMediumLandGaussCannonProjectile
TDFGauss02 = ClassProjectile(TDFGaussCannonProjectile) {
    FxTrails = {'/effects/emitters/gauss_cannon_munition_trail_03_emit.bp',},
}
TypeClass = TDFGauss02
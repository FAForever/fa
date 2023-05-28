--
-- Terran Gauss Cannon Projectile : UEB2301 (uef T2 pd)
--

local TDFGaussCannonProjectile = import("/lua/terranprojectiles.lua").TDFMediumLandGaussCannonProjectile

TDFGauss02 = ClassProjectile(TDFGaussCannonProjectile) {
    FxTrails = {'/effects/emitters/gauss_cannon_munition_trail_03_emit.bp',},
}
TypeClass = TDFGauss02

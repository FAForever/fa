--
-- Terran Gauss Cannon Projectile : UEB2301 (uef T2 pd)
--

local TDFGaussCannonProjectile = import('/lua/terranprojectiles.lua').TDFLandGaussCannonProjectile

TDFGauss01 = Class(TDFGaussCannonProjectile) {
    FxTrails = {'/effects/emitters/gauss_cannon_munition_trail_03_emit.bp',},
    FxLandHitScale = 0.35,
}
TypeClass = TDFGauss01

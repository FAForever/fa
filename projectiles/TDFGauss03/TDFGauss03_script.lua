--
-- Terran Gauss Cannon Projectile (UES0302) UEF Battleship
--
local TDFGaussCannonProjectile = import("/lua/terranprojectiles.lua").TDFBigShipGaussCannonProjectile
TDFGauss03 = ClassProjectile(TDFGaussCannonProjectile) {
    FxTrails = {'/effects/emitters/gauss_cannon_munition_trail_03_emit.bp',},
    FxLandHitScale = 1.5,
}
TypeClass = TDFGauss03


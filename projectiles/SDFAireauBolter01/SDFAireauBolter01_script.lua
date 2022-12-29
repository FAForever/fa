-- File     :  /data/projectiles/SDFAireauBolter01/SDFAireauBolter01_script.lua
-- Author(s):  Gordon Duclos, Aaron Lundquist
-- Summary  :  Aire-au Bolter Projectile script, XSL0202
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--------------------------------------------------------------------------------
SDFAireauBolter = ClassProjectile(import("/lua/seraphimprojectiles.lua").SAireauBolter) {
    FxAirUnitHitScale =  0.75,
    FxLandHitScale =  0.75,
    FxNoneHitScale =  0.75,
    FxPropHitScale =  0.75,
    FxShieldHitScale =  0.75,
    FxUnitHitScale =  0.75,
    FxWaterHitScale =  0.75,
    FxOnKilledScale = 0.75,
    FxTrailScale =  0.75,
}
TypeClass = SDFAireauBolter
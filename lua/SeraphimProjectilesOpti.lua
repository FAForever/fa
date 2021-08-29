------------------------------------------------------------
--
--  File     :  /cdimage/lua/seraphimprojectiles.lua
--  Author(s):  Gordon Duclos, Greg Kohne, Matt Vainio, Aaron Lundquist
--
--  Summary  : Seraphim projectile base class definitions
--
--  Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------

--------------------------------------------------------------------------
--  SERAPHIM PROJECTILES SCRIPTS
--------------------------------------------------------------------------

local EffectTemplate = import('/lua/EffectTemplates.lua')
local DefaultProjectileFile = import('/lua/sim/defaultprojectiles.lua')
local MultiPolyTrailProjectile = DefaultProjectileFile.MultiPolyTrailProjectileOpti

SThunthoArtilleryShell = Class(MultiPolyTrailProjectile) {

    FxImpactTrajectoryAligned = false,

    FxImpactLand = EffectTemplate.SThunderStormCannonHit,
    FxImpactNone = EffectTemplate.SThunderStormCannonHit,
    FxImpactProjectile = false,
    FxImpactProp = EffectTemplate.SThunderStormCannonHit,
    FxImpactUnderWater = false,
    FxImpactUnit = EffectTemplate.SThunderStormCannonHit,

    FxTrails = EffectTemplate.SThunderStormCannonProjectileTrails,

    PolyTrails = EffectTemplate.SThunderStormCannonProjectilePolyTrails,
    PolyTrailOffset = false,
}

SThunthoArtilleryShell2 = Class(MultiPolyTrailProjectile) {

    FxImpactTrajectoryAligned = false,

    FxImpactLand = EffectTemplate.SThunderStormCannonLandHit,
    FxImpactWater= EffectTemplate.SThunderStormCannonLandHit,
    FxImpactNone = EffectTemplate.SThunderStormCannonHit,
    FxImpactProjectile = false,
    FxImpactProp = EffectTemplate.SThunderStormCannonHit,
    FxImpactUnderWater = false,
    FxImpactUnit = EffectTemplate.SThunderStormCannonUnitHit,

    FxTrails = false,

    PolyTrails = EffectTemplate.SThunderStormCannonProjectilePolyTrails,
    PolyTrailOffset = false,
}

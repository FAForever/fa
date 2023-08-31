--
-- script for projectile BoneAttached
--
local EmitterProjectile = import("/lua/sim/defaultprojectiles.lua").EmitterProjectile

EffectThrustTransport01 = Class(EmitterProjectile) {
    FxTrails = { },
    FxTrailScale = 1,
    FxTrailOffset = 0,

    FxUnitHitScale = 1,
    FxImpactUnit = {'/effects/emitters/air_landing_dust_01_emit.bp',},

    FxLandHitScale = 1,
    FxImpactLand = {'/effects/emitters/air_landing_dust_01_emit.bp',},

    FxWaterHitScale = 0.5,
    FxImpactWater = {'/effects/emitters/destruction_water_splash_ripples_01_emit.bp',
        '/effects/emitters/destruction_water_splash_wash_01_emit.bp',
        },

    FxUnderWaterHitScale = 1,
    FxNoneHitScale = 1,
    FxImpactNone = { },
}

TypeClass = EffectThrustTransport01


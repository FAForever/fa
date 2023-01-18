local DefaultProjectileFile = import("/lua/sim/defaultprojectiles.lua")
local MultiPolyTrailProjectile = DefaultProjectileFile.MultiPolyTrailProjectile
local EffectTemplate = import("/lua/effecttemplates.lua")

---@class TShellPhalanxProjectile : MultiPolyTrailProjectile
TShellPhalanxProjectile = Class(MultiPolyTrailProjectile) {
    PolyTrails = EffectTemplate.TPhalanxGunPolyTrails,
    PolyTrailOffset = EffectTemplate.TPhalanxGunPolyTrailsOffsets,
    FxImpactUnit = EffectTemplate.TRiotGunHitUnit01,
    FxImpactAirUnit = EffectTemplate.TRiotGunHitUnit01,
    FxImpactProp = EffectTemplate.TRiotGunHitUnit01,
    FxImpactNone = EffectTemplate.FireCloudSml01,
    FxImpactLand = EffectTemplate.TRiotGunHit01,
    FxImpactProjectile = EffectTemplate.TMissileHit02,
    FxProjectileHitScale = 1.0,
}
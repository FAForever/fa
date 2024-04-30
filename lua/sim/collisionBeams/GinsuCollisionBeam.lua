local EffectTemplate = import("/lua/effecttemplates.lua")

local SCCollisionBeam = import("/lua/sim/collisionBeams/SCCollisionBeam.lua").SCCollisionBeam

-- Not used. Barely visible, gray, unimpressive beam.
---@class GinsuCollisionBeam : SCCollisionBeam
GinsuCollisionBeam = Class(SCCollisionBeam) {
    FxBeam = EffectTemplate.TAAGinsuBeam,
    FxBeamEndPoint = EffectTemplate.TAAGinsuEndPoint,
    FxImpactUnit = EffectTemplate.TAAGinsuHitUnit02,
    FxUnitHitScale = 0.125,
    FxImpactLand = EffectTemplate.TAAGinsuHitLand02,
    FxLandHitScale = 0.1625,
}

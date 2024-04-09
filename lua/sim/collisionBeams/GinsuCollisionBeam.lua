local EffectTemplate = import("/lua/effecttemplates.lua")

local SCCollisionBeam = import("/lua/defaultcollisionbeams.lua").SCCollisionBeam

-------------------------------
--   Ginsu COLLISION BEAM
-------------------------------
---@class GinsuCollisionBeam : SCCollisionBeam
GinsuCollisionBeam = Class(SCCollisionBeam) {
    FxBeam = EffectTemplate.TAAGinsuBeam,
    FxBeamEndPoint = EffectTemplate.TAAGinsuEndPoint,
    FxImpactUnit = EffectTemplate.TAAGinsuHitUnit02,
    FxUnitHitScale = 0.125,
    FxImpactLand = EffectTemplate.TAAGinsuHitLand02,
    FxLandHitScale = 0.1625,
}

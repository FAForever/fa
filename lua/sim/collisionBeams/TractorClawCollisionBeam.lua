local EffectTemplate = import("/lua/effecttemplates.lua")

local CollisionBeam = import("/lua/sim/collisionbeam.lua").CollisionBeam

---@class TractorClawCollisionBeam : CollisionBeam
TractorClawCollisionBeam = Class(CollisionBeam) {
    
    FxBeam = {EffectTemplate.ACollossusTractorBeam01},
    FxBeamEndPoint = {EffectTemplate.ACollossusTractorBeamGlow02},
    FxBeamEndPointScale = 1.0,
    FxBeamStartPoint = { EffectTemplate.ACollossusTractorBeamGlow01 },
}

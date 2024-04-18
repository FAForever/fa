local EffectTemplate = import("/lua/effecttemplates.lua")

local CollisionBeam = import("/lua/sim/collisionbeam.lua").CollisionBeam

-- Old beam for Aeon Galactic Colossus's Tractor Claws before rework by FAF
---@class TractorClawCollisionBeam : CollisionBeam
TractorClawCollisionBeam = Class(CollisionBeam) {
    
    FxBeam = { EffectTemplate.ACollossusTractorBeam01 },
    FxBeamEndPoint = { EffectTemplate.ACollossusTractorBeamGlow02 },
    FxBeamEndPointScale = 1.0,
    FxBeamStartPoint = { EffectTemplate.ACollossusTractorBeamGlow01 },
}

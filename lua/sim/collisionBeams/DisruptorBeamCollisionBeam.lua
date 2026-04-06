local EffectTemplate = import("/lua/effecttemplates.lua")

local SCCollisionBeam = import("/lua/sim/collisionbeams/sccollisionbeam.lua").SCCollisionBeam

-- Not used. Aeon style beam sized for a small unit
---@class DisruptorBeamCollisionBeam : SCCollisionBeam
DisruptorBeamCollisionBeam = Class(SCCollisionBeam) {

    FxBeam = EffectTemplate.ADisruptorBeamBeam,
    FxBeamEndPoint = EffectTemplate.ADisruptorBeamHit01, -- These effects could be improved, they do not repeat
    FxBeamEndPointScale = 1.0,

    FxBeamStartPoint = EffectTemplate.ADisruptorBeamMuzzleFlash01,

    
}

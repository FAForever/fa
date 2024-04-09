local EffectTemplate = import("/lua/effecttemplates.lua")

local SCCollisionBeam = import("/lua/defaultcollisionbeams.lua").SCCollisionBeam

---@class DisruptorBeamCollisionBeam : SCCollisionBeam
DisruptorBeamCollisionBeam = Class(SCCollisionBeam) {

    FxBeam = EffectTemplate.ADisruptorBeamBeam,
    FxBeamEndPoint = EffectTemplate.ADisruptorBeamHit01,
    FxBeamEndPointScale = 1.0,

    FxBeamStartPoint = EffectTemplate.ADisruptorBeamMuzzleFlash01,

    
}

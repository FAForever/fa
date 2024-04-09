local EffectTemplate = import("/lua/effecttemplates.lua")

local SCCollisionBeam = import("/lua/defaultcollisionbeams.lua").SCCollisionBeam

------------------------------------
--   PARTICLE CANNON COLLISION BEAM
------------------------------------
---@class ParticleCannonCollisionBeam : SCCollisionBeam
ParticleCannonCollisionBeam = Class(SCCollisionBeam) {
    FxBeam = EffectTemplate.CParticleCannonBeam,
    FxBeamEndPoint = EffectTemplate.CParticleCannonHit02,
    FxBeamEndPointScale = 1,
}

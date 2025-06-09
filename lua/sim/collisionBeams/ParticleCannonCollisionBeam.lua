local EffectTemplate = import("/lua/effecttemplates.lua")

local SCCollisionBeam = import("/lua/sim/collisionbeams/sccollisionbeam.lua").SCCollisionBeam

-- Not used anymore. Tiny Cybran pulsing beam previously used by Cerberus and Rhino CDFParticleCannon
---@class ParticleCannonCollisionBeam : SCCollisionBeam
ParticleCannonCollisionBeam = Class(SCCollisionBeam) {
    FxBeam = EffectTemplate.CParticleCannonBeam,
    FxBeamEndPoint = EffectTemplate.CParticleCannonHit02,
    FxBeamEndPointScale = 1,
}

local SCCollisionBeam = import("/lua/defaultcollisionbeams.lua").SCCollisionBeam

------------------------------------
--   PARTICLE CANNON COLLISION BEAM
------------------------------------
---@class ParticleCannonCollisionBeam : SCCollisionBeam
ParticleCannonCollisionBeam = Class(SCCollisionBeam) {
    FxBeam = {
		'/effects/emitters/particle_cannon_beam_01_emit.bp',
        '/effects/emitters/particle_cannon_beam_02_emit.bp'
	},
    FxBeamEndPoint = {
		'/effects/emitters/particle_cannon_end_01_emit.bp',
		'/effects/emitters/particle_cannon_end_02_emit.bp',
	},
    FxBeamEndPointScale = 1,
}

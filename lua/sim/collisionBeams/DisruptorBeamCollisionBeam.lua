local SCCollisionBeam = import("/lua/defaultcollisionbeams.lua").SCCollisionBeam

---@class DisruptorBeamCollisionBeam : SCCollisionBeam
DisruptorBeamCollisionBeam = Class(SCCollisionBeam) {

    FxBeam = {'/effects/emitters/disruptor_beam_01_emit.bp'},
    FxBeamEndPoint = { 
        '/effects/emitters/aeon_commander_disruptor_hit_01_emit.bp', 
        '/effects/emitters/aeon_commander_disruptor_hit_02_emit.bp', 
    },
    FxBeamEndPointScale = 1.0,

    FxBeamStartPoint = { 
        '/effects/emitters/aeon_commander_disruptor_flash_01_emit.bp', 
        '/effects/emitters/aeon_commander_disruptor_flash_02_emit.bp', 
    },

    
}

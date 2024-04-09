local SCCollisionBeam = import("/lua/defaultcollisionbeams.lua").SCCollisionBeam

------------------------------------
--   ZAPPER COLLISION BEAM
------------------------------------
---@class ZapperCollisionBeam : SCCollisionBeam
ZapperCollisionBeam = Class(SCCollisionBeam) {
    FxBeam = {'/effects/emitters/zapper_beam_01_emit.bp'},
    FxBeamEndPoint = {'/effects/emitters/cannon_muzzle_flash_01_emit.bp',
                       '/effects/emitters/sparks_07_emit.bp',},
}


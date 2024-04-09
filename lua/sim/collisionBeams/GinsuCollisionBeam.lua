local SCCollisionBeam = import("/lua/defaultcollisionbeams.lua").SCCollisionBeam

-------------------------------
--   Ginsu COLLISION BEAM
-------------------------------
---@class GinsuCollisionBeam : SCCollisionBeam
GinsuCollisionBeam = Class(SCCollisionBeam) {
    FxBeam = {'/effects/emitters/riot_gun_beam_01_emit.bp',
              '/effects/emitters/riot_gun_beam_02_emit.bp',},
    FxBeamEndPoint = {'/effects/emitters/sparks_02_emit.bp',},


    FxImpactUnit = {'/effects/emitters/riotgun_hit_flash_01_emit.bp',},
    FxUnitHitScale = 0.125,
    FxImpactLand = {'/effects/emitters/destruction_land_hit_puff_01_emit.bp',
                    '/effects/emitters/destruction_explosion_flash_01_emit.bp'},
    FxLandHitScale = 0.1625,
}

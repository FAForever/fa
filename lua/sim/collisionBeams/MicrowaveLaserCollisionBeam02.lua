local EffectTemplate = import("/lua/effecttemplates.lua")

local MicrowaveLaserCollisionBeam01 = import("/lua/defaultcollisionbeams.lua").MicrowaveLaserCollisionBeam01

---@class MicrowaveLaserCollisionBeam02 : MicrowaveLaserCollisionBeam01
MicrowaveLaserCollisionBeam02 = Class(MicrowaveLaserCollisionBeam01) {
    TerrainImpactScale = 1,
    FxBeamStartPoint = EffectTemplate.CMicrowaveLaserMuzzle01,
    FxBeam = {'/effects/emitters/microwave_laser_beam_02_emit.bp'},
    FxBeamEndPoint = EffectTemplate.CMicrowaveLaserEndPoint01,
}

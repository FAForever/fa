local EffectTemplate = import("/lua/effecttemplates.lua")

local MicrowaveLaserCollisionBeam01 = import("/lua/sim/collisionbeams/microwavelasercollisionbeam01.lua").MicrowaveLaserCollisionBeam01

-- Smaller MicrowaveLaser used by Cybran ACU URL0001's CDFHeavyMicrowaveLaserGeneratorCom
---@class MicrowaveLaserCollisionBeam02 : MicrowaveLaserCollisionBeam01
MicrowaveLaserCollisionBeam02 = Class(MicrowaveLaserCollisionBeam01) {
    TerrainImpactScale = 1,
    FxBeamStartPoint = EffectTemplate.CMicrowaveLaserMuzzle01,
    FxBeam = EffectTemplate.CMicrowaveLaserBeam02,
    FxBeamEndPoint = EffectTemplate.CMicrowaveLaserEndPoint01,
}

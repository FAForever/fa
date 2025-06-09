local EffectTemplate = import("/lua/effecttemplates.lua")

local UltraChromaticBeamGeneratorCollisionBeam = import("/lua/sim/collisionbeams/ultrachromaticbeamgeneratorcollisionbeam.lua").UltraChromaticBeamGeneratorCollisionBeam

-- Used by Seraphim Destroyer XSS0201's SDFUltraChromaticBeamGenerator02
---@class UltraChromaticBeamGeneratorCollisionBeam02 : UltraChromaticBeamGeneratorCollisionBeam
UltraChromaticBeamGeneratorCollisionBeam02 = Class(UltraChromaticBeamGeneratorCollisionBeam) {
	FxBeamStartPoint = EffectTemplate.SUltraChromaticBeamGeneratorMuzzle02,
}

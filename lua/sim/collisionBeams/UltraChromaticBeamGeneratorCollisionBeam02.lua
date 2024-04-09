local EffectTemplate = import("/lua/effecttemplates.lua")

local UltraChromaticBeamGeneratorCollisionBeam = import("/lua/defaultcollisionbeams.lua").UltraChromaticBeamGeneratorCollisionBeam

-- This is for sera destro and sera T2 point defense. (adjustment for ship muzzleflash)
---@class UltraChromaticBeamGeneratorCollisionBeam02 : UltraChromaticBeamGeneratorCollisionBeam
UltraChromaticBeamGeneratorCollisionBeam02 = Class(UltraChromaticBeamGeneratorCollisionBeam) {
	FxBeamStartPoint = EffectTemplate.SUltraChromaticBeamGeneratorMuzzle02,
}


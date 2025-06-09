local DefaultBeamWeapon = import("/lua/sim/defaultweapons.lua").DefaultBeamWeapon
local EffectTemplate = import('/lua/effecttemplates.lua')
local LightningSmallCollisionBeam = import("/lua/sim/collisionbeams/lightningsmallcollisionbeam.lua").LightningSmallCollisionBeam

--- Used by DSLK004
---@class SAALightningWeapon : DefaultProjectileWeapon
SAALightningWeapon = ClassWeapon(DefaultBeamWeapon) {
    BeamType = LightningSmallCollisionBeam,
    FxMuzzleFlash = { },
    FxUpackingChargeEffects = EffectTemplate.CMicrowaveLaserCharge01,
    FxUpackingChargeEffectScale = 0.2,
}

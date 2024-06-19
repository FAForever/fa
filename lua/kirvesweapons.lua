local WeaponFile = import("/lua/sim/defaultweapons.lua")
local DefaultProjectileWeapon = WeaponFile.DefaultProjectileWeapon
local DefaultBeamWeapon = WeaponFile.DefaultBeamWeapon
local OriginalEffectTemplate = import("/lua/effecttemplates.lua")
local EffectTemplate = import("/lua/kirveseffects.lua")
local CollisionBeamFile = import("/lua/kirvesbeams.lua")

---@class TargetingLaser : DefaultBeamWeapon
TargetingLaser = Class(DefaultBeamWeapon) {
    BeamType = CollisionBeamFile.TargetingCollisionBeam,
    FxMuzzleFlash = {'/effects/emitters/particle_cannon_muzzle_01_emit.bp'},
    FxBeamEndPointScale = 0.01,
}

---@class TargetingLaserInvisible : TargetingLaser
TargetingLaserInvisible = Class(TargetingLaser) {
    BeamType = CollisionBeamFile.TargetingCollisionBeamInvisible,
    FxMuzzleFlash = { },
}

---@class TAAPhalanxWeapon : DefaultProjectileWeapon
TAAPhalanxWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TPhalanxGunMuzzleFlash,
    FxShellEject  = EffectTemplate.TPhalanxGunShells,

    ---@param self TAAPhalanxWeapon
    ---@param muzzle Bone
    PlayFxMuzzleSequence = function(self, muzzle)
        DefaultProjectileWeapon.PlayFxMuzzleSequence(self, muzzle)
        for k, v in self.FxShellEject do
            CreateAttachedEmitter(self.unit, 'Shells_Left', self.unit.Army, v)
            CreateAttachedEmitter(self.unit, 'Shells_Right', self.unit.Army, v)
        end
    end,
}

---@class SDFUnstablePhasonBeam : DefaultBeamWeapon
SDFUnstablePhasonBeam = Class(DefaultBeamWeapon) {
    BeamType = CollisionBeamFile.UnstablePhasonLaserCollisionBeam,
    FxMuzzleFlash = { },
    FxChargeMuzzleFlash = { }, --------OriginalEffectTemplate.SExperimentalUnstablePhasonLaserMuzzle01,
    FxUpackingChargeEffects = OriginalEffectTemplate.CMicrowaveLaserCharge01,
    FxUpackingChargeEffectScale = 0.2,
}

---@class SDFUnstablePhasonBeam2 : DefaultBeamWeapon
SDFUnstablePhasonBeam2 = Class(DefaultBeamWeapon) {
    BeamType = CollisionBeamFile.UnstablePhasonLaserCollisionBeam2,
    FxMuzzleFlash = { },
    FxChargeMuzzleFlash = { }, --------OriginalEffectTemplate.SExperimentalUnstablePhasonLaserMuzzle01,
    FxUpackingChargeEffects = OriginalEffectTemplate.CMicrowaveLaserCharge01,
    FxUpackingChargeEffectScale = 0.1,
    FxBeamEndPointScale = 0.01,
}

---@class Dummy : DefaultBeamWeapon
Dummy = Class(DefaultBeamWeapon) {
    BeamType = CollisionBeamFile.TargetingCollisionBeam,

    FxBeamEndPointScale = 0.01,
}

-- kept for mod backwards compatibility
local KamikazeWeapon = WeaponFile.KamikazeWeapon
local BareBonesWeapon = WeaponFile.BareBonesWeapon
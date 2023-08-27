--****************************************************************************
--**
--**  File     :  /lua/terranweapons.lua
--**  Author(s):  John Comes, David Tomandl, Gordon Duclos
--**
--**  Summary  :  Terran-specific weapon definitions
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local WeaponFile = import("/lua/sim/defaultweapons.lua")
local CollisionBeams = import("/lua/defaultcollisionbeams.lua")
local DefaultProjectileWeapon = WeaponFile.DefaultProjectileWeapon
local DefaultBeamWeapon = WeaponFile.DefaultBeamWeapon
local OrbitalDeathLaserCollisionBeam = CollisionBeams.OrbitalDeathLaserCollisionBeam
local EffectTemplate = import("/lua/effecttemplates.lua")

---@class TDFFragmentationGrenadeLauncherWeapon : DefaultProjectileWeapon
TDFFragmentationGrenadeLauncherWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.THeavyFragmentationGrenadeMuzzleFlash,
}

---@class TDFPlasmaCannonWeapon : DefaultProjectileWeapon
TDFPlasmaCannonWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TPlasmaGatlingCannonMuzzleFlash,
}

---@class TIFFragLauncherWeapon : DefaultProjectileWeapon
TIFFragLauncherWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TPlasmaCannonHeavyMuzzleFlash,
}

---@class TDFHeavyPlasmaGatlingWeapon : DefaultProjectileWeapon
TDFHeavyPlasmaGatlingWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TPlasmaCannonHeavyMuzzleFlash,
}

---@class TDFLightPlasmaCannonWeapon : DefaultProjectileWeapon
TDFLightPlasmaCannonWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TPlasmaCannonLightMuzzleFlash,
}

---@class TDFHeavyPlasmaCannonWeapon : DefaultProjectileWeapon
TDFHeavyPlasmaCannonWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TPlasmaCannonHeavyMuzzleFlash,
}

---@class TDFHeavyPlasmaGatlingCannonWeapon : DefaultProjectileWeapon
TDFHeavyPlasmaGatlingCannonWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.THeavyPlasmaGatlingCannonMuzzleFlash,
}

---@class TDFOverchargeWeapon : OverchargeWeapon
TDFOverchargeWeapon = ClassWeapon(WeaponFile.OverchargeWeapon) {
    FxMuzzleFlash = EffectTemplate.TCommanderOverchargeFlash01,
    DesiredWeaponLabel = 'RightZephyr'
}

---@class TDFMachineGunWeapon : DefaultProjectileWeapon
TDFMachineGunWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = {
        '/effects/emitters/machinegun_muzzle_fire_01_emit.bp',
        '/effects/emitters/machinegun_muzzle_fire_02_emit.bp',
    },
}

---@class TDFGaussCannonWeapon : DefaultProjectileWeapon
TDFGaussCannonWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TGaussCannonFlash,
}

---@class TDFShipGaussCannonWeapon : DefaultProjectileWeapon
TDFShipGaussCannonWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TShipGaussCannonFlash,
}

---@class TDFLandGaussCannonWeapon : DefaultProjectileWeapon
TDFLandGaussCannonWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TLandGaussCannonFlash,
}

---@class TDFZephyrCannonWeapon : DefaultProjectileWeapon
TDFZephyrCannonWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TLaserMuzzleFlash,
}

---@class TDFRiotWeapon : DefaultProjectileWeapon
TDFRiotWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFx,
}

---@class TAAGinsuRapidPulseWeapon : DefaultProjectileWeapon
TAAGinsuRapidPulseWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = { },
}

---@class TDFIonizedPlasmaCannon : DefaultProjectileWeapon
TDFIonizedPlasmaCannon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TIonizedPlasmaGatlingCannonMuzzleFlash,
}

---@class TDFHiroPlasmaCannon : DefaultBeamWeapon
TDFHiroPlasmaCannon = ClassWeapon(DefaultBeamWeapon) {
    BeamType = CollisionBeams.TDFHiroCollisionBeam,
    FxMuzzleFlash = { },
}

---@class TAAFlakArtilleryCannon : DefaultProjectileWeapon
TAAFlakArtilleryCannon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TFlakCannonMuzzleFlash01,
}

---@class TAALinkedRailgun : DefaultProjectileWeapon
TAALinkedRailgun = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TRailGunMuzzleFlash01,
}

---@class TAirToAirLinkedRailgun : DefaultProjectileWeapon
TAirToAirLinkedRailgun = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TRailGunMuzzleFlash02,
}

---@class TIFCruiseMissileUnpackingLauncher : DefaultProjectileWeapon
TIFCruiseMissileUnpackingLauncher = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = { },
}

---@class TIFCruiseMissileLauncher : DefaultProjectileWeapon
TIFCruiseMissileLauncher = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TIFCruiseMissileLaunchSmoke,
}

---@class TIFCruiseMissileLauncherSub : DefaultProjectileWeapon
TIFCruiseMissileLauncherSub = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TIFCruiseMissileLaunchUnderWater,
}

---@class TSAMLauncher : DefaultProjectileWeapon
TSAMLauncher = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TAAMissileLaunch,
}

---@class TANTorpedoLandWeapon : DefaultProjectileWeapon
TANTorpedoLandWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = {
        '/effects/emitters/default_muzzle_flash_01_emit.bp',
        '/effects/emitters/default_muzzle_flash_02_emit.bp',
        '/effects/emitters/torpedo_underwater_launch_01_emit.bp',
    },
}

---@class TANTorpedoAngler : DefaultProjectileWeapon
TANTorpedoAngler = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = {
        '/effects/emitters/default_muzzle_flash_01_emit.bp',
        '/effects/emitters/default_muzzle_flash_02_emit.bp',
        '/effects/emitters/torpedo_underwater_launch_01_emit.bp',
    },
}

---@class TIFSmartCharge : DefaultProjectileWeapon
TIFSmartCharge = ClassWeapon(DefaultProjectileWeapon) {

    ---@param self TIFSmartCharge
    ---@param muzzle Bone
    ---@return Projectile
    CreateProjectileAtMuzzle = function(self, muzzle)
        local proj = DefaultProjectileWeapon.CreateProjectileAtMuzzle(self, muzzle)
        local blueprint = self.Blueprint.DepthCharge
        if blueprint then
            proj:AddDepthCharge(blueprint)
        end

        return proj
    end,
}

---@class TIFStrategicMissileWeapon : DefaultProjectileWeapon
TIFStrategicMissileWeapon = ClassWeapon(DefaultProjectileWeapon) {}

---@class TIFArtilleryWeapon : DefaultProjectileWeapon
TIFArtilleryWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TIFArtilleryMuzzleFlash
}

---@class TIFCarpetBombWeapon : DefaultProjectileWeapon
TIFCarpetBombWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/antiair_muzzle_fire_02_emit.bp',},

    --- This function creates the projectile, and happens when the unit is trying to fire
    --- Called from inside RackSalvoFiringState
    ---@param self TIFCarpetBombWeapon
    ---@param muzzle string
    ---@return Projectile
    CreateProjectileAtMuzzle = function(self, muzzle)
        -- Adapt this function to keep the correct target lock during carpet bombing
        local data = self.CurrentSalvoData
        if data and data.usestore then
            local pos = data.targetpos
            if pos then -- We are repeating, and have lost our original target
                self:SetTargetGround(pos)
            end
        end

        return DefaultProjectileWeapon.CreateProjectileAtMuzzle(self, muzzle)
    end,
}

---@class TIFSmallYieldNuclearBombWeapon : DefaultProjectileWeapon
TIFSmallYieldNuclearBombWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/antiair_muzzle_fire_02_emit.bp',},
}

---@class TIFHighBallisticMortarWeapon : DefaultProjectileWeapon
TIFHighBallisticMortarWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TMobileMortarMuzzleEffect01,
}

---@class TAMInterceptorWeapon : DefaultProjectileWeapon
TAMInterceptorWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/terran_antinuke_launch_01_emit.bp',},
}

---@class TAMPhalanxWeapon : DefaultProjectileWeapon
TAMPhalanxWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TPhalanxGunMuzzleFlash,
    FxShellEject  = EffectTemplate.TPhalanxGunShells,

    ---@param self TAMPhalanxWeapon
    ---@param muzzle Bone
    PlayFxMuzzleSequence = function(self, muzzle)
        DefaultProjectileWeapon.PlayFxMuzzleSequence(self, muzzle)
        local unit = self.unit
        local turrentBonePitch = self.Blueprint.TurretBonePitch
        local army = self.Army
        for k, v in self.FxShellEject do
            CreateAttachedEmitter(unit, turrentBonePitch, army, v)
        end
    end,
}

---@class TOrbitalDeathLaserBeamWeapon : DefaultBeamWeapon
TOrbitalDeathLaserBeamWeapon = ClassWeapon(DefaultBeamWeapon) {
    BeamType = OrbitalDeathLaserCollisionBeam,
}

-- Kept for Mod backwards compatibility
local BareBonesWeapon = WeaponFile.BareBonesWeapon
local GinsuCollisionBeam = CollisionBeams.GinsuCollisionBeam
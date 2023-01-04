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
    FxMuzzleFlash = {},
}

---@class TDFIonizedPlasmaCannon : DefaultProjectileWeapon
TDFIonizedPlasmaCannon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TIonizedPlasmaGatlingCannonMuzzleFlash,
}

---@class TDFHiroPlasmaCannon : DefaultBeamWeapon
TDFHiroPlasmaCannon = ClassWeapon(DefaultBeamWeapon) {
    BeamType = CollisionBeams.TDFHiroCollisionBeam,
    FxMuzzleFlash = {},
    FxChargeMuzzleFlash = {},
    FxUpackingChargeEffects = {},
    FxUpackingChargeEffectScale = 1,

    ---@param self TDFHiroPlasmaCannon
    PlayFxWeaponUnpackSequence = function(self)
        if not self.ContBeamOn then
            local bp = self:GetBlueprint()
            for k, v in self.FxUpackingChargeEffects do
                for ek, ev in bp.RackBones[self.CurrentRackSalvoNumber].MuzzleBones do
                    CreateAttachedEmitter(self.unit, ev, self.unit.Army, v):ScaleEmitter(self.FxUpackingChargeEffectScale)
                end
            end
            DefaultBeamWeapon.PlayFxWeaponUnpackSequence(self)
        end
    end,
}

---@class TAAFlakArtilleryCannon : DefaultProjectileWeapon
TAAFlakArtilleryCannon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TFlakCannonMuzzleFlash01,
    
    --- Custom over-ride for this weapon, so it passes data and damageTable
    ---@param self TAAFlakArtilleryCannon
    ---@param bone Bone
    ---@return Projectile
    CreateProjectileForWeapon = function(self, bone)
        local proj = self:CreateProjectile(bone)
        local damageTable = self:GetDamageTable()
        local blueprint = self:GetBlueprint()
        local data = {
            Instigator = self.unit,
            Damage = blueprint.DoTDamage,
            Duration = blueprint.DoTDuration,
            Frequency = blueprint.DoTFrequency,
            Radius = blueprint.DamageRadius,
            Type = 'Normal',
            DamageFriendly = blueprint.DamageFriendly,
        }
        
        if proj and not proj:BeenDestroyed() then
            proj:PassDamageData(damageTable)
            proj:PassData(data)
        end

        return proj
    end
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
    FxMuzzleFlash = {},
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
    CreateProjectileAtMuzzle = function(self, muzzle)
        local proj = DefaultProjectileWeapon.CreateProjectileAtMuzzle(self, muzzle)
        local tbl = self:GetBlueprint().DepthCharge
        proj:AddDepthCharge(tbl)
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

    ---@param self TIFCarpetBombWeapon
    ---@param bone Bone
    ---@return Projectile | nil
    CreateProjectileForWeapon = function(self, bone)
        local projectile = self:CreateProjectile(bone)
        local damageTable = self:GetDamageTable()
        local blueprint = self:GetBlueprint()
        local data = {
            Instigator = self.unit,
            Damage = blueprint.DoTDamage,
            Duration = blueprint.DoTDuration,
            Frequency = blueprint.DoTFrequency,
            Radius = blueprint.DamageRadius,
            Type = 'Normal',
            DamageFriendly = blueprint.DamageFriendly,
        }
        if projectile and not projectile:BeenDestroyed() then
            projectile:PassData(data)
            projectile:PassDamageData(damageTable)
        end
        return projectile
    end,

    --- This function creates the projectile, and happens when the unit is trying to fire
    --- Called from inside RackSalvoFiringState
    ---@param self TIFCarpetBombWeapon
    ---@param muzzle string
    CreateProjectileAtMuzzle = function(self, muzzle)
        -- Adapt this function to keep the correct target lock during carpet bombing
        local data = self.CurrentSalvoData
        if data and data.usestore then
            local pos = data.targetpos
            if pos then -- We are repeating, and have lost our original target
                self:SetTargetGround(pos)
            end
        end

        DefaultProjectileWeapon.CreateProjectileAtMuzzle(self, muzzle)
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
        for k, v in self.FxShellEject do
            CreateAttachedEmitter(self.unit, self:GetBlueprint().TurretBonePitch, self.unit.Army, v)
        end
    end,
}

---@class TOrbitalDeathLaserBeamWeapon : DefaultBeamWeapon
TOrbitalDeathLaserBeamWeapon = ClassWeapon(DefaultBeamWeapon) {
    BeamType = OrbitalDeathLaserCollisionBeam,
    FxUpackingChargeEffects = {},
    FxUpackingChargeEffectScale = 1,

    ---@param self TOrbitalDeathLaserBeamWeapon
    PlayFxWeaponUnpackSequence = function(self)
        local bp = self:GetBlueprint()
        for k, v in self.FxUpackingChargeEffects do
            for ek, ev in bp.RackBones[self.CurrentRackSalvoNumber].MuzzleBones do
                CreateAttachedEmitter(self.unit, ev, self.unit.Army, v):ScaleEmitter(self.FxUpackingChargeEffectScale)
            end
        end
        DefaultBeamWeapon.PlayFxWeaponUnpackSequence(self)
    end,
}

-- Kept for Mod backwards compatibility
local BareBonesWeapon = WeaponFile.BareBonesWeapon
local GinsuCollisionBeam = CollisionBeams.GinsuCollisionBeam
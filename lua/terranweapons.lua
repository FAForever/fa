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
local BareBonesWeapon = WeaponFile.BareBonesWeapon
local DefaultProjectileWeapon = WeaponFile.DefaultProjectileWeapon
local DefaultBeamWeapon = WeaponFile.DefaultBeamWeapon
local GinsuCollisionBeam = CollisionBeams.GinsuCollisionBeam
local OrbitalDeathLaserCollisionBeam = CollisionBeams.OrbitalDeathLaserCollisionBeam
local EffectTemplate = import("/lua/effecttemplates.lua")

---@class TDFFragmentationGrenadeLauncherWeapon : DefaultProjectileWeapon
TDFFragmentationGrenadeLauncherWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.THeavyFragmentationGrenadeMuzzleFlash,
}

---@class TDFPlasmaCannonWeapon : DefaultProjectileWeapon
TDFPlasmaCannonWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TPlasmaGatlingCannonMuzzleFlash,
}

---@class TIFFragLauncherWeapon : DefaultProjectileWeapon
TIFFragLauncherWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TPlasmaCannonHeavyMuzzleFlash,
}

---@class TDFHeavyPlasmaGatlingWeapon : DefaultProjectileWeapon
TDFHeavyPlasmaGatlingWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TPlasmaCannonHeavyMuzzleFlash,
}

---@class TDFLightPlasmaCannonWeapon : DefaultProjectileWeapon
TDFLightPlasmaCannonWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TPlasmaCannonLightMuzzleFlash,
}

---@class TDFHeavyPlasmaCannonWeapon : DefaultProjectileWeapon
TDFHeavyPlasmaCannonWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TPlasmaCannonHeavyMuzzleFlash,
}

---@class TDFHeavyPlasmaGatlingCannonWeapon : DefaultProjectileWeapon
TDFHeavyPlasmaGatlingCannonWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.THeavyPlasmaGatlingCannonMuzzleFlash,
}

---@class TDFOverchargeWeapon : OverchargeWeapon
TDFOverchargeWeapon = Class(WeaponFile.OverchargeWeapon) {
    FxMuzzleFlash = EffectTemplate.TCommanderOverchargeFlash01,
    DesiredWeaponLabel = 'RightZephyr'
}

---@class TDFMachineGunWeapon : DefaultProjectileWeapon
TDFMachineGunWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {
        '/effects/emitters/machinegun_muzzle_fire_01_emit.bp',
        '/effects/emitters/machinegun_muzzle_fire_02_emit.bp',
    },
}

---@class TDFGaussCannonWeapon : DefaultProjectileWeapon
TDFGaussCannonWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TGaussCannonFlash,
}

---@class TDFShipGaussCannonWeapon : DefaultProjectileWeapon
TDFShipGaussCannonWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TShipGaussCannonFlash,
}

---@class TDFLandGaussCannonWeapon : DefaultProjectileWeapon
TDFLandGaussCannonWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TLandGaussCannonFlash,
}

---@class TDFZephyrCannonWeapon : DefaultProjectileWeapon
TDFZephyrCannonWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TLaserMuzzleFlash,
}

---@class TDFRiotWeapon : DefaultProjectileWeapon
TDFRiotWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFx,
}

---@class TAAGinsuRapidPulseWeapon : DefaultProjectileWeapon
TAAGinsuRapidPulseWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {},
}

---@class TDFIonizedPlasmaCannon : DefaultProjectileWeapon
TDFIonizedPlasmaCannon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TIonizedPlasmaGatlingCannonMuzzleFlash,
}

---@class TDFHiroPlasmaCannon : DefaultBeamWeapon
TDFHiroPlasmaCannon = Class(DefaultBeamWeapon) {
    BeamType = CollisionBeams.TDFHiroCollisionBeam,
    FxMuzzleFlash = {},
    FxChargeMuzzleFlash = {},
    FxUpackingChargeEffects = {},
    FxUpackingChargeEffectScale = 1,

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
TAAFlakArtilleryCannon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TFlakCannonMuzzleFlash01,
    -- Custom over-ride for this weapon, so it passes data and damageTable
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
TAALinkedRailgun = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TRailGunMuzzleFlash01,
}


---@class TAirToAirLinkedRailgun : DefaultProjectileWeapon
TAirToAirLinkedRailgun = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TRailGunMuzzleFlash02,
}

---@class TIFCruiseMissileUnpackingLauncher : DefaultProjectileWeapon
TIFCruiseMissileUnpackingLauncher = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {},
}
---@class TIFCruiseMissileLauncher : DefaultProjectileWeapon
TIFCruiseMissileLauncher = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TIFCruiseMissileLaunchSmoke,
}

---@class TIFCruiseMissileLauncherSub : DefaultProjectileWeapon
TIFCruiseMissileLauncherSub = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TIFCruiseMissileLaunchUnderWater,
}

---@class TSAMLauncher : DefaultProjectileWeapon
TSAMLauncher = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TAAMissileLaunch,
}

---@class TANTorpedoLandWeapon : DefaultProjectileWeapon
TANTorpedoLandWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {
        '/effects/emitters/default_muzzle_flash_01_emit.bp',
        '/effects/emitters/default_muzzle_flash_02_emit.bp',
        '/effects/emitters/torpedo_underwater_launch_01_emit.bp',
    },
}

---@class TANTorpedoAngler : DefaultProjectileWeapon
TANTorpedoAngler = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {
        '/effects/emitters/default_muzzle_flash_01_emit.bp',
        '/effects/emitters/default_muzzle_flash_02_emit.bp',
        '/effects/emitters/torpedo_underwater_launch_01_emit.bp',
    },
}

---@class TIFSmartCharge : DefaultProjectileWeapon
TIFSmartCharge = Class(DefaultProjectileWeapon) {
    CreateProjectileAtMuzzle = function(self, muzzle)
        local proj = DefaultProjectileWeapon.CreateProjectileAtMuzzle(self, muzzle)
        local tbl = self:GetBlueprint().DepthCharge
        proj:AddDepthCharge(tbl)
    end,
}

---@class TIFStrategicMissileWeapon : DefaultProjectileWeapon
TIFStrategicMissileWeapon = Class(DefaultProjectileWeapon) {}

---@class TIFArtilleryWeapon : DefaultProjectileWeapon
TIFArtilleryWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TIFArtilleryMuzzleFlash
}

---@class TIFCarpetBombWeapon : DefaultProjectileWeapon
TIFCarpetBombWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/antiair_muzzle_fire_02_emit.bp',},

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

    -- This function creates the projectile, and happens when the unit is trying to fire
    -- Called from inside RackSalvoFiringState
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
TIFSmallYieldNuclearBombWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/antiair_muzzle_fire_02_emit.bp',},
}

---@class TIFHighBallisticMortarWeapon : DefaultProjectileWeapon
TIFHighBallisticMortarWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TMobileMortarMuzzleEffect01,
}

---@class TAMInterceptorWeapon : DefaultProjectileWeapon
TAMInterceptorWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/terran_antinuke_launch_01_emit.bp',},
}

---@class TAMPhalanxWeapon : DefaultProjectileWeapon
TAMPhalanxWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TPhalanxGunMuzzleFlash,
    FxShellEject  = EffectTemplate.TPhalanxGunShells,

    PlayFxMuzzleSequence = function(self, muzzle)
        DefaultProjectileWeapon.PlayFxMuzzleSequence(self, muzzle)
        for k, v in self.FxShellEject do
            CreateAttachedEmitter(self.unit, self:GetBlueprint().TurretBonePitch, self.unit.Army, v)
        end
    end,
}

---@class TOrbitalDeathLaserBeamWeapon : DefaultBeamWeapon
TOrbitalDeathLaserBeamWeapon = Class(DefaultBeamWeapon) {
    BeamType = OrbitalDeathLaserCollisionBeam,
    FxUpackingChargeEffects = {},
    FxUpackingChargeEffectScale = 1,

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

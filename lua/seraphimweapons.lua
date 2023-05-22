-- File     :  /lua/seraphimweapons.lua
-- Author(s):  Greg Kohne, Gordon Duclos, Matt Vainio, Aaron Lundquist, Dru Staltman, Jessica St. Croix
-- Summary  :  Default definitions of Seraphim weapons
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------------------------------------------   

local WeaponFile = import("/lua/sim/defaultweapons.lua")
local CollisionBeamFile = import("/lua/defaultcollisionbeams.lua")
local DefaultProjectileWeapon = WeaponFile.DefaultProjectileWeapon
local DefaultBeamWeapon = WeaponFile.DefaultBeamWeapon
local OverchargeWeapon = WeaponFile.OverchargeWeapon
local EffectTemplate = import("/lua/effecttemplates.lua")
local SCCollisionBeam = import("/lua/defaultcollisionbeams.lua").SCCollisionBeam

---@class SANAnaitTorpedo : DefaultProjectileWeapon
SANAnaitTorpedo = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SAnaitTorpedoMuzzleFlash,
}

---@class SDFExperimentalPhasonProj : DefaultProjectileWeapon
SDFExperimentalPhasonProj = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SDFExperimentalPhasonProjMuzzleFlash,
    FxChargeMuzzleFlash = EffectTemplate.SDFExperimentalPhasonProjChargeMuzzleFlash,
}

---@class SDFAireauWeapon : DefaultProjectileWeapon
SDFAireauWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SDFAireauWeaponMuzzleFlash,
}

---@class SDFSinnuntheWeapon : DefaultProjectileWeapon
SDFSinnuntheWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SDFSinnutheWeaponMuzzleFlash,
    FxChargeMuzzleFlash = EffectTemplate.SDFSinnutheWeaponChargeMuzzleFlash
}

---@class SIFInainoWeapon : DefaultProjectileWeapon
SIFInainoWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SIFInainoLaunch01,
}

---@class SIFHuAntiNukeWeapon : DefaultProjectileWeapon
SIFHuAntiNukeWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SKhuAntiNukeMuzzleFlash,
}

---@class SIFExperimentalStrategicMissile : DefaultProjectileWeapon
SIFExperimentalStrategicMissile = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SIFExperimentalStrategicMissileLaunch01,
    FxChargeMuzzleFlash = EffectTemplate.SIFExperimentalStrategicMissileChargeLaunch01,
}

---@class SDFPhasicAutoGunWeapon : DefaultProjectileWeapon
SDFPhasicAutoGunWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.PhasicAutoGunMuzzleFlash,
}

---@class SDFHeavyPhasicAutoGunTankWeapon : DefaultProjectileWeapon
SDFHeavyPhasicAutoGunTankWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.HeavyPhasicAutoGunTankMuzzleFlash,
}

---@class SDFHeavyPhasicAutoGunWeapon : DefaultProjectileWeapon
SDFHeavyPhasicAutoGunWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.HeavyPhasicAutoGunMuzzleFlash,
}

---@class SDFOhCannon : DefaultProjectileWeapon
SDFOhCannon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.OhCannonMuzzleFlash,
}

---@class SDFOhCannon02 : DefaultProjectileWeapon
SDFOhCannon02 = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.OhCannonMuzzleFlash02,
}

---@class SDFShriekerCannon : DefaultProjectileWeapon
SDFShriekerCannon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.ShriekerCannonMuzzleFlash,
}

-- Units: XSL0111
---@class SIFLaanseTacticalMissileLauncher : DefaultProjectileWeapon
SIFLaanseTacticalMissileLauncher = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SLaanseMissleMuzzleFlash,
}

-- Units: XSB2303
---@class SIFZthuthaamArtilleryCannon : DefaultProjectileWeapon
SIFZthuthaamArtilleryCannon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash= EffectTemplate.SZthuthaamArtilleryMuzzleFlash,
    FxChargeMuzzleFlash= EffectTemplate.SZthuthaamArtilleryChargeMuzzleFlash,
}

-- Units: XSL0303
---@class SDFThauCannon : DefaultProjectileWeapon
SDFThauCannon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.STauCannonMuzzleFlash,
    FxMuzzleTerrainTypeName = 'ThauTerrainMuzzle',

    ---@param self SDFThauCannon
    ---@param muzzle string
    PlayFxMuzzleSequence = function(self, muzzle)
        DefaultProjectileWeapon.PlayFxMuzzleSequence(self, muzzle)
        local pos = self.unit:GetPosition()
        local TerrainType = GetTerrainType(pos.x,pos.z)
        local effectTable = TerrainType.FXOther[self.unit.Layer][self.FxMuzzleTerrainTypeName]
        if effectTable ~= nil then
            local army = self.unit.Army
            for k, v in effectTable do
                CreateAttachedEmitter(self.unit, muzzle, army, v)
            end
        end
    end,
}

-- Units: XSL0303
---@class SDFAireauBolterWeapon : DefaultProjectileWeapon
SDFAireauBolterWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SAireauBolterMuzzleFlash,
}

-- Units: XSL0202
---@class SDFAireauBolterWeapon02 : DefaultProjectileWeapon
SDFAireauBolterWeapon02 = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SAireauBolterMuzzleFlash02,
}

-- Units: XSL0303
---@class SANUallCavitationTorpedo : DefaultProjectileWeapon
SANUallCavitationTorpedo = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SUallTorpedoMuzzleFlash
}

---@class SANAnaitTorpedo : DefaultProjectileWeapon
SANAnaitTorpedo = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SAnaitTorpedoMuzzleFlash
}

---@class SANHeavyCavitationTorpedo : DefaultProjectileWeapon
SANHeavyCavitationTorpedo = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SHeavyCavitationTorpedoMuzzleFlash
}

---@class SANHeavyCavitationTorpedo02 : DefaultProjectileWeapon
SANHeavyCavitationTorpedo02 = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SHeavyCavitationTorpedoMuzzleFlash02
}

---@class SDFChronotronCannonWeapon : DefaultProjectileWeapon
SDFChronotronCannonWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SChronotronCannonMuzzle,
    FxChargeMuzzleFlash = EffectTemplate.SChronotronCannonMuzzleCharge,
}

---@class SDFChronotronCannonOverChargeWeapon : OverchargeWeapon
SDFChronotronCannonOverChargeWeapon = ClassWeapon(OverchargeWeapon) {
    FxMuzzleFlash = EffectTemplate.SChronotronCannonOverChargeMuzzle,
    DesiredWeaponLabel = 'ChronotronCannon'
}

-- Units: XSL0301
---@class SDFLightChronotronCannonWeapon : DefaultProjectileWeapon
SDFLightChronotronCannonWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SLightChronotronCannonMuzzleFlash,
}

---@class SDFLightChronotronCannonOverchargeWeapon : OverchargeWeapon
SDFLightChronotronCannonOverchargeWeapon = ClassWeapon(OverchargeWeapon) {
    FxMuzzleFlash = EffectTemplate.SLightChronotronCannonOverChargeMuzzleFlash,
    DesiredWeaponLabel = 'LightChronatronCannon'
}

---@class SAAShleoCannonWeapon : DefaultProjectileWeapon
SAAShleoCannonWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SShleoCannonMuzzleFlash,
}

---@class SAAOlarisCannonWeapon : DefaultProjectileWeapon
SAAOlarisCannonWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxChargeEffects = EffectTemplate.SOlarisCannonMuzzleCharge,
    FxMuzzleFlash = EffectTemplate.SOlarisCannonMuzzleFlash01,
}

---@class SAALosaareAutoCannonWeapon : DefaultProjectileWeapon
SAALosaareAutoCannonWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SLosaareAutoCannonMuzzleFlash,
}
---@class SAALosaareAutoCannonWeaponAirUnit : DefaultProjectileWeapon
SAALosaareAutoCannonWeaponAirUnit = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SLosaareAutoCannonMuzzleFlashAirUnit,
}
---@class SAALosaareAutoCannonWeaponSeaUnit : DefaultProjectileWeapon
SAALosaareAutoCannonWeaponSeaUnit = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SLosaareAutoCannonMuzzleFlashSeaUnit,
}

---@class SDFAjelluAntiTorpedoDefense : DefaultProjectileWeapon
SDFAjelluAntiTorpedoDefense = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SDFAjelluAntiTorpedoLaunch01,
}

---@class SIFThunthoCannonWeapon : DefaultProjectileWeapon
SIFThunthoCannonWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SThunderStormCannonMuzzleFlash,
}

---@class SIFSuthanusArtilleryCannon : DefaultProjectileWeapon
SIFSuthanusArtilleryCannon = ClassWeapon(DefaultProjectileWeapon) {
    FxChargeMuzzleFlash = EffectTemplate.SRifterArtilleryChargeMuzzleFlash,
    FxMuzzleFlash = EffectTemplate.SRifterArtilleryMuzzleFlash,
}

---@class SIFSuthanusMobileArtilleryCannon : DefaultProjectileWeapon
SIFSuthanusMobileArtilleryCannon = ClassWeapon(DefaultProjectileWeapon) {
    FxChargeMuzzleFlash = EffectTemplate.SRifterMobileArtilleryChargeMuzzleFlash,
    FxMuzzleFlash = EffectTemplate.SRifterMobileArtilleryMuzzleFlash,
}

---@class SDFExperimentalPhasonLaser : DefaultBeamWeapon
SDFExperimentalPhasonLaser = ClassWeapon(DefaultBeamWeapon) {
    BeamType = CollisionBeamFile.ExperimentalPhasonLaserCollisionBeam,
    FxUpackingChargeEffects = EffectTemplate.SChargeExperimentalPhasonLaser,
    FxUpackingChargeEffectScale = 1,

    ---@param self SDFExperimentalPhasonLaser
    PlayFxWeaponUnpackSequence = function(self)
        if not self.ContBeamOn then
            local army = self.unit.Army
            local bp = self.Blueprint
            for k, v in self.FxUpackingChargeEffects do
                for ek, ev in bp.RackBones[self.CurrentRackSalvoNumber].MuzzleBones do
                    CreateAttachedEmitter(self.unit, ev, army, v):ScaleEmitter(self.FxUpackingChargeEffectScale)
                end
            end
            DefaultBeamWeapon.PlayFxWeaponUnpackSequence(self)
        end
    end,
}

---@class SDFUnstablePhasonBeam : DefaultBeamWeapon
SDFUnstablePhasonBeam = ClassWeapon(DefaultBeamWeapon) {
    BeamType = CollisionBeamFile.UnstablePhasonLaserCollisionBeam,
    FxUpackingChargeEffects = EffectTemplate.CMicrowaveLaserCharge01,
    FxUpackingChargeEffectScale = 1,
}

---@class SDFUltraChromaticBeamGenerator : DefaultBeamWeapon
SDFUltraChromaticBeamGenerator = ClassWeapon(DefaultBeamWeapon) {
    BeamType = CollisionBeamFile.UltraChromaticBeamGeneratorCollisionBeam,
    FxUpackingChargeEffects = EffectTemplate.SChargeUltraChromaticBeamGenerator,
    FxUpackingChargeEffectScale = 1,

    ---@param self SDFUltraChromaticBeamGenerator
    PlayFxWeaponUnpackSequence = function(self)
        if not self.ContBeamOn then
            local army = self.unit.Army
            local bp = self.Blueprint
            for k, v in self.FxUpackingChargeEffects do
                for ek, ev in bp.RackBones[self.CurrentRackSalvoNumber].MuzzleBones do
                    CreateAttachedEmitter(self.unit, ev, army, v):ScaleEmitter(self.FxUpackingChargeEffectScale)
                end
            end
            DefaultBeamWeapon.PlayFxWeaponUnpackSequence(self)
        end
    end,
}

---@class SDFUltraChromaticBeamGenerator02 : SDFUltraChromaticBeamGenerator
SDFUltraChromaticBeamGenerator02 = ClassWeapon(SDFUltraChromaticBeamGenerator) {
    BeamType = CollisionBeamFile.UltraChromaticBeamGeneratorCollisionBeam02,
}

---@class SLaanseMissileWeapon : DefaultProjectileWeapon
SLaanseMissileWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SLaanseMissleMuzzleFlash,
}

---@class SExperimentalStrategicMissileWeapon : DefaultProjectileWeapon
SExperimentalStrategicMissileWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SExperimentalStrategicMissileMuzzleFlash,
}

---@class SAMElectrumMissileDefense : DefaultProjectileWeapon
SAMElectrumMissileDefense = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SElectrumMissleDefenseMuzzleFlash,
}

---@class SDFBombOtheWeapon : DefaultProjectileWeapon
SDFBombOtheWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SOtheBombMuzzleFlash,
}

---@class SIFBombZhanaseeWeapon : DefaultProjectileWeapon
SIFBombZhanaseeWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SZhanaseeMuzzleFlash01,
}

---@class SDFHeavyQuarnonCannon : DefaultProjectileWeapon
SDFHeavyQuarnonCannon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SHeavyQuarnonCannonMuzzleFlash,
}

---@class SDFSniperShotNormalMode : DefaultProjectileWeapon
SDFSniperShotNormalMode = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SDFSniperShotNormalMuzzleFlash,
}

---@class SDFSniperShotSniperMode : DefaultProjectileWeapon
SDFSniperShotSniperMode = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SDFSniperShotMuzzleFlash,
}

---@class SB0OhwalliExperimentalStrategicBombWeapon : DefaultProjectileWeapon
SB0OhwalliExperimentalStrategicBombWeapon = ClassWeapon(DefaultProjectileWeapon) {}

---@class PhasonCollisionBeam : SCCollisionBeam
PhasonCollisionBeam = ClassWeapon(SCCollisionBeam) {
    FxBeamStartPoint = {
        '/Effects/Emitters/seraphim_experimental_phasonproj_muzzle_flash_01_emit.bp',
        '/Effects/Emitters/seraphim_experimental_phasonproj_muzzle_flash_02_emit.bp',
        '/Effects/Emitters/seraphim_experimental_phasonproj_muzzle_flash_03_emit.bp',
        '/Effects/Emitters/seraphim_experimental_phasonproj_muzzle_flash_04_emit.bp',
        '/Effects/Emitters/seraphim_experimental_phasonproj_muzzle_flash_05_emit.bp',
        '/Effects/Emitters/seraphim_experimental_phasonproj_muzzle_flash_06_emit.bp',
        '/Effects/Emitters/seraphim_electricity_emit.bp'
    },
    FxBeam = {
        '/Effects/Emitters/seraphim_lightning_beam_01_emit.bp',
    },
    FxBeamEndPoint = {
        '/Effects/Emitters/seraphim_lightning_hit_01_emit.bp',
        '/Effects/Emitters/seraphim_lightning_hit_02_emit.bp',
        '/Effects/Emitters/seraphim_lightning_hit_03_emit.bp',
        '/Effects/Emitters/seraphim_lightning_hit_04_emit.bp',
    },
    TerrainImpactType = 'LargeBeam01',
    TerrainImpactScale = 0.2,
    SplatTexture = 'czar_mark01_albedo',
    ScorchSplatDropTime = 0.25,
}

---@class PhasonCollisionBeam2 : PhasonCollisionBeam
PhasonCollisionBeam2 = ClassWeapon(PhasonCollisionBeam) {
    FxBeam = { '/Effects/Emitters/seraphim_lightning_beam_02_emit.bp', },
    TerrainImpactScale = 0.1,

    ---@param self PhasonCollisionBeam2
    ---@param impactType string
    ---@param targetEntity Prop|Unit
    OnImpact = function(self, impactType, targetEntity)
        local scorching = self.Scorching
        if impactType == 'Terrain' then
            if scorching == nil then
            scorching = self.Trash:Add(ForkThread(self.ScorchThread,self))
            end
        elseif not impactType == 'Unit' then
            KillThread(scorching)
            scorching = nil
        end
        PhasonCollisionBeam.OnImpact(self, impactType, targetEntity)
    end,

    ---@param self PhasonCollisionBeam2
    OnDisable = function(self)
        PhasonCollisionBeam.OnDisable(self)
        local scorching = self.Scorching
        KillThread(scorching)
        scorching = nil
    end,

    ---@param self PhasonCollisionBeam2
    ScorchThread = function(self)
        local size = 1 + (Random() * 1.1)
        local CurrentPosition = self:GetPosition(1)
        local LastPosition = Vector(0,0,0)
        local skipCount = 1
        local Util = import("/lua/utilities.lua")

        while true do
            if Util.GetDistanceBetweenTwoVectors(CurrentPosition, LastPosition) > 0.25 or skipCount > 100 then
                CreateSplat(CurrentPosition, Util.GetRandomFloat(0,2*math.pi), self.SplatTexture, size, size, 100, 100, self.Army)
                LastPosition = CurrentPosition
                skipCount = 1
            else
                skipCount = skipCount + self.ScorchSplatDropTime
            end

            WaitSeconds(self.ScorchSplatDropTime)
            size = 1 + (Random() * 1.1)
            CurrentPosition = self:GetPosition(1)
        end
    end,
}

---@class PhasonBeam : DefaultBeamWeapon
PhasonBeam = ClassWeapon(DefaultBeamWeapon) {
    BeamType = PhasonCollisionBeam,
    FxMuzzleFlash = import("/lua/effecttemplates.lua").NoEffects,
    FxChargeMuzzleFlash = import("/lua/effecttemplates.lua").NoEffects,
    FxUpackingChargeEffects = EffectTemplate.CMicrowaveLaserCharge01,
    FxUpackingChargeEffectScale = 0.2,
}

--- Kept Mod Support
local KamikazeWeapon = WeaponFile.KamikazeWeapon
local BareBonesWeapon = WeaponFile.BareBonesWeapon
local Explosion = import("/lua/defaultexplosions.lua")
local DisruptorBeamCollisionBeam = CollisionBeamFile.DisruptorBeamCollisionBeam
local QuantumBeamGeneratorCollisionBeam = CollisionBeamFile.QuantumBeamGeneratorCollisionBeam
local PhasonLaserCollisionBeam = CollisionBeamFile.PhasonLaserCollisionBeam
local TractorClawCollisionBeam = CollisionBeamFile.TractorClawCollisionBeam
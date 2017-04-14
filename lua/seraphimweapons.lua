--****************************************************************************
--**
--**  File     :  /lua/seraphimweapons.lua
--**  Author(s):  Greg Kohne, Gordon Duclos,
--**              Matt Vainio, Aaron Lundquist, Dru Staltman, Jessica St. Croix
--**
--**  Summary  :  Default definitions of Seraphim weapons
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local WeaponFile = import('/lua/sim/DefaultWeapons.lua')
local CollisionBeamFile = import('defaultcollisionbeams.lua')
local KamikazeWeapon = WeaponFile.KamikazeWeapon
local BareBonesWeapon = WeaponFile.BareBonesWeapon
local DefaultProjectileWeapon = WeaponFile.DefaultProjectileWeapon
local DefaultBeamWeapon = WeaponFile.DefaultBeamWeapon
local OverchargeWeapon = WeaponFile.OverchargeWeapon

local Explosion = import('defaultexplosions.lua')
local DisruptorBeamCollisionBeam = CollisionBeamFile.DisruptorBeamCollisionBeam
local QuantumBeamGeneratorCollisionBeam = CollisionBeamFile.QuantumBeamGeneratorCollisionBeam
local PhasonLaserCollisionBeam = CollisionBeamFile.PhasonLaserCollisionBeam
local TractorClawCollisionBeam = CollisionBeamFile.TractorClawCollisionBeam
local EffectTemplate = import('/lua/EffectTemplates.lua')

local Game = import('/lua/game.lua')   ----added for CBFP
local DefaultBuffField = import('/lua/DefaultBuffField.lua').DefaultBuffField     ----added for CBFP

SeraphimBuffField = Class(DefaultBuffField) {     ----added for CBFP
    FieldVisualEmitter = '/effects/emitters/seraphim_regenerative_aura_01_emit.bp',     ----added for CBFP
}

SANAnaitTorpedo = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SAnaitTorpedoMuzzleFlash,
}

SDFExperimentalPhasonProj = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SDFExperimentalPhasonProjMuzzleFlash,
    FxChargeMuzzleFlash = EffectTemplate.SDFExperimentalPhasonProjChargeMuzzleFlash,
}

SDFAireauWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SDFAireauWeaponMuzzleFlash,
}

SDFSinnuntheWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SDFSinnutheWeaponMuzzleFlash,
    FxChargeMuzzleFlash = EffectTemplate.SDFSinnutheWeaponChargeMuzzleFlash
}

SIFInainoWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SIFInainoLaunch01,
}

SIFHuAntiNukeWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SKhuAntiNukeMuzzleFlash,
}

SIFExperimentalStrategicMissile = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SIFExperimentalStrategicMissileLaunch01,
    FxChargeMuzzleFlash = EffectTemplate.SIFExperimentalStrategicMissileChargeLaunch01,
}

SDFPhasicAutoGunWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.PhasicAutoGunMuzzleFlash,
}

SDFHeavyPhasicAutoGunTankWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.HeavyPhasicAutoGunTankMuzzleFlash,
}

SDFHeavyPhasicAutoGunWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.HeavyPhasicAutoGunMuzzleFlash,
}

SDFOhCannon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.OhCannonMuzzleFlash,
}

SDFOhCannon02 = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.OhCannonMuzzleFlash02,
}

SDFShriekerCannon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.ShriekerCannonMuzzleFlash,
}

-- Units: XSL0111
SIFLaanseTacticalMissileLauncher = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SLaanseMissleMuzzleFlash,
}

-- Units: XSB2303
SIFZthuthaamArtilleryCannon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash= EffectTemplate.SZthuthaamArtilleryMuzzleFlash,
    FxChargeMuzzleFlash= EffectTemplate.SZthuthaamArtilleryChargeMuzzleFlash,
}

-- Units: XSL0303
SDFThauCannon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.STauCannonMuzzleFlash,
    FxMuzzleTerrainTypeName = 'ThauTerrainMuzzle',

    PlayFxMuzzleSequence = function(self, muzzle)
        DefaultProjectileWeapon.PlayFxMuzzleSequence(self, muzzle)
        local pos = self.unit:GetPosition()
        local TerrainType = GetTerrainType(pos.x,pos.z)
        local effectTable = TerrainType.FXOther[self.unit:GetCurrentLayer()][self.FxMuzzleTerrainTypeName]
        if effectTable ~= nil then
            local army = self.unit:GetArmy()
            for k, v in effectTable do
                CreateAttachedEmitter(self.unit, muzzle, army, v)
            end
        end
    end,
}

-- Units: XSL0303
SDFAireauBolterWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SAireauBolterMuzzleFlash,
}

-- Units: XSL0202
SDFAireauBolterWeapon02 = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SAireauBolterMuzzleFlash02,
}

-- Units: XSL0303
SANUallCavitationTorpedo = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SUallTorpedoMuzzleFlash
}

SANAnaitTorpedo = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SAnaitTorpedoMuzzleFlash
}

SANHeavyCavitationTorpedo = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SHeavyCavitationTorpedoMuzzleFlash
}

SANHeavyCavitationTorpedo02 = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SHeavyCavitationTorpedoMuzzleFlash02
}

SDFChronotronCannonWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SChronotronCannonMuzzle,
    FxChargeMuzzleFlash = EffectTemplate.SChronotronCannonMuzzleCharge,
}

SDFChronotronCannonOverChargeWeapon = Class(OverchargeWeapon) {
    FxMuzzleFlash = EffectTemplate.SChronotronCannonOverChargeMuzzle,
    DesiredWeaponLabel = 'ChronotronCannon'
}

-- Units: XSL0301
SDFLightChronotronCannonWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SLightChronotronCannonMuzzleFlash,
}

SDFLightChronotronCannonOverchargeWeapon = Class(OverchargeWeapon) {
    FxMuzzleFlash = EffectTemplate.SLightChronotronCannonOverChargeMuzzleFlash,
    DesiredWeaponLabel = 'LightChronatronCannon'
}

SAAShleoCannonWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SShleoCannonMuzzleFlash,
}

SAAOlarisCannonWeapon = Class(DefaultProjectileWeapon) {
    FxChargeEffects = EffectTemplate.SOlarisCannonMuzzleCharge,
    FxMuzzleFlash = EffectTemplate.SOlarisCannonMuzzleFlash01,
}

SAALosaareAutoCannonWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SLosaareAutoCannonMuzzleFlash,
}
SAALosaareAutoCannonWeaponAirUnit = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SLosaareAutoCannonMuzzleFlashAirUnit,
}
SAALosaareAutoCannonWeaponSeaUnit = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SLosaareAutoCannonMuzzleFlashSeaUnit,
}


SDFAjelluAntiTorpedoDefense = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SDFAjelluAntiTorpedoLaunch01,
}

SIFThunthoCannonWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SThunderStormCannonMuzzleFlash,
}

SIFSuthanusArtilleryCannon = Class(DefaultProjectileWeapon) {
    FxChargeMuzzleFlash = EffectTemplate.SRifterArtilleryChargeMuzzleFlash,
    FxMuzzleFlash = EffectTemplate.SRifterArtilleryMuzzleFlash,
}

SIFSuthanusMobileArtilleryCannon = Class(DefaultProjectileWeapon) {
    FxChargeMuzzleFlash = EffectTemplate.SRifterMobileArtilleryChargeMuzzleFlash,
    FxMuzzleFlash = EffectTemplate.SRifterMobileArtilleryMuzzleFlash,
}

SDFExperimentalPhasonLaser = Class(DefaultBeamWeapon) {
    BeamType = CollisionBeamFile.ExperimentalPhasonLaserCollisionBeam,
    FxMuzzleFlash = {},
    FxChargeMuzzleFlash = {},
    FxUpackingChargeEffects = EffectTemplate.SChargeExperimentalPhasonLaser,
    FxUpackingChargeEffectScale = 1,

    PlayFxWeaponUnpackSequence = function(self)
        if not self.ContBeamOn then
            local army = self.unit:GetArmy()
            local bp = self:GetBlueprint()
            for k, v in self.FxUpackingChargeEffects do
                for ek, ev in bp.RackBones[self.CurrentRackSalvoNumber].MuzzleBones do
                    CreateAttachedEmitter(self.unit, ev, army, v):ScaleEmitter(self.FxUpackingChargeEffectScale)
                end
            end
            DefaultBeamWeapon.PlayFxWeaponUnpackSequence(self)
        end
    end,
}

SDFUnstablePhasonBeam = Class(DefaultBeamWeapon) {
    BeamType = CollisionBeamFile.UnstablePhasonLaserCollisionBeam,
    FxMuzzleFlash = {},
    FxChargeMuzzleFlash = {}, --------EffectTemplate.SExperimentalUnstablePhasonLaserMuzzle01,
    FxUpackingChargeEffects = EffectTemplate.CMicrowaveLaserCharge01,
    FxUpackingChargeEffectScale = 1,
}

SDFUltraChromaticBeamGenerator = Class(DefaultBeamWeapon) {
    BeamType = CollisionBeamFile.UltraChromaticBeamGeneratorCollisionBeam,
    FxMuzzleFlash = {},
    FxChargeMuzzleFlash = {},
    FxUpackingChargeEffects = EffectTemplate.SChargeUltraChromaticBeamGenerator,
    FxUpackingChargeEffectScale = 1,

    PlayFxWeaponUnpackSequence = function(self)
        if not self.ContBeamOn then
            local army = self.unit:GetArmy()
            local bp = self:GetBlueprint()
            for k, v in self.FxUpackingChargeEffects do
                for ek, ev in bp.RackBones[self.CurrentRackSalvoNumber].MuzzleBones do
                    CreateAttachedEmitter(self.unit, ev, army, v):ScaleEmitter(self.FxUpackingChargeEffectScale)
                end
            end
            DefaultBeamWeapon.PlayFxWeaponUnpackSequence(self)
        end
    end,
}

SDFUltraChromaticBeamGenerator02 = Class(SDFUltraChromaticBeamGenerator) {
    BeamType = CollisionBeamFile.UltraChromaticBeamGeneratorCollisionBeam02,
}

SLaanseMissileWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SLaanseMissleMuzzleFlash,
}

SExperimentalStrategicMissileWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SExperimentalStrategicMissileMuzzleFlash,
}

SAMElectrumMissileDefense = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SElectrumMissleDefenseMuzzleFlash,
}

SDFBombOtheWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SOtheBombMuzzleFlash,
}

SIFBombZhanaseeWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SZhanaseeMuzzleFlash01,
}

SDFHeavyQuarnonCannon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SHeavyQuarnonCannonMuzzleFlash,
}

SDFSniperShotNormalMode = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SDFSniperShotNormalMuzzleFlash,
}

SDFSniperShotSniperMode = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SDFSniperShotMuzzleFlash,
}

SB0OhwalliExperimentalStrategicBombWeapon = Class(DefaultProjectileWeapon) {
}

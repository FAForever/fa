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

local WeaponFile = import("/lua/sim/defaultweapons.lua")
local CollisionBeamFile = import("/lua/defaultcollisionbeams.lua")
local KamikazeWeapon = WeaponFile.KamikazeWeapon
local BareBonesWeapon = WeaponFile.BareBonesWeapon
local DefaultProjectileWeapon = WeaponFile.DefaultProjectileWeapon
local DefaultBeamWeapon = WeaponFile.DefaultBeamWeapon
local OverchargeWeapon = WeaponFile.OverchargeWeapon

local Explosion = import("/lua/defaultexplosions.lua")
local DisruptorBeamCollisionBeam = CollisionBeamFile.DisruptorBeamCollisionBeam
local QuantumBeamGeneratorCollisionBeam = CollisionBeamFile.QuantumBeamGeneratorCollisionBeam
local PhasonLaserCollisionBeam = CollisionBeamFile.PhasonLaserCollisionBeam
local TractorClawCollisionBeam = CollisionBeamFile.TractorClawCollisionBeam
local EffectTemplate = import("/lua/effecttemplates.lua")

---@class SANAnaitTorpedo : DefaultProjectileWeapon
SANAnaitTorpedo = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SAnaitTorpedoMuzzleFlash,
}

---@class SDFExperimentalPhasonProj : DefaultProjectileWeapon
SDFExperimentalPhasonProj = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SDFExperimentalPhasonProjMuzzleFlash,
    FxChargeMuzzleFlash = EffectTemplate.SDFExperimentalPhasonProjChargeMuzzleFlash,
}

---@class SDFAireauWeapon : DefaultProjectileWeapon
SDFAireauWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SDFAireauWeaponMuzzleFlash,
}

---@class SDFSinnuntheWeapon : DefaultProjectileWeapon
SDFSinnuntheWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SDFSinnutheWeaponMuzzleFlash,
    FxChargeMuzzleFlash = EffectTemplate.SDFSinnutheWeaponChargeMuzzleFlash
}

---@class SIFInainoWeapon : DefaultProjectileWeapon
SIFInainoWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SIFInainoLaunch01,
}

---@class SIFHuAntiNukeWeapon : DefaultProjectileWeapon
SIFHuAntiNukeWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SKhuAntiNukeMuzzleFlash,
}

---@class SIFExperimentalStrategicMissile : DefaultProjectileWeapon
SIFExperimentalStrategicMissile = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SIFExperimentalStrategicMissileLaunch01,
    FxChargeMuzzleFlash = EffectTemplate.SIFExperimentalStrategicMissileChargeLaunch01,
}

---@class SDFPhasicAutoGunWeapon : DefaultProjectileWeapon
SDFPhasicAutoGunWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.PhasicAutoGunMuzzleFlash,
}

---@class SDFHeavyPhasicAutoGunTankWeapon : DefaultProjectileWeapon
SDFHeavyPhasicAutoGunTankWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.HeavyPhasicAutoGunTankMuzzleFlash,
}

---@class SDFHeavyPhasicAutoGunWeapon : DefaultProjectileWeapon
SDFHeavyPhasicAutoGunWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.HeavyPhasicAutoGunMuzzleFlash,
}

---@class SDFOhCannon : DefaultProjectileWeapon
SDFOhCannon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.OhCannonMuzzleFlash,
}

---@class SDFOhCannon02 : DefaultProjectileWeapon
SDFOhCannon02 = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.OhCannonMuzzleFlash02,
}

---@class SDFShriekerCannon : DefaultProjectileWeapon
SDFShriekerCannon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.ShriekerCannonMuzzleFlash,
}

-- Units: XSL0111
---@class SIFLaanseTacticalMissileLauncher : DefaultProjectileWeapon
SIFLaanseTacticalMissileLauncher = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SLaanseMissleMuzzleFlash,
}

-- Units: XSB2303
---@class SIFZthuthaamArtilleryCannon : DefaultProjectileWeapon
SIFZthuthaamArtilleryCannon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash= EffectTemplate.SZthuthaamArtilleryMuzzleFlash,
    FxChargeMuzzleFlash= EffectTemplate.SZthuthaamArtilleryChargeMuzzleFlash,
}

-- Units: XSL0303
---@class SDFThauCannon : DefaultProjectileWeapon
SDFThauCannon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.STauCannonMuzzleFlash,
    FxMuzzleTerrainTypeName = 'ThauTerrainMuzzle',

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
SDFAireauBolterWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SAireauBolterMuzzleFlash,
}

-- Units: XSL0202
---@class SDFAireauBolterWeapon02 : DefaultProjectileWeapon
SDFAireauBolterWeapon02 = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SAireauBolterMuzzleFlash02,
}

-- Units: XSL0303
---@class SANUallCavitationTorpedo : DefaultProjectileWeapon
SANUallCavitationTorpedo = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SUallTorpedoMuzzleFlash
}

---@class SANAnaitTorpedo : DefaultProjectileWeapon
SANAnaitTorpedo = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SAnaitTorpedoMuzzleFlash
}

---@class SANHeavyCavitationTorpedo : DefaultProjectileWeapon
SANHeavyCavitationTorpedo = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SHeavyCavitationTorpedoMuzzleFlash
}

---@class SANHeavyCavitationTorpedo02 : DefaultProjectileWeapon
SANHeavyCavitationTorpedo02 = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SHeavyCavitationTorpedoMuzzleFlash02
}

---@class SDFChronotronCannonWeapon : DefaultProjectileWeapon
SDFChronotronCannonWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SChronotronCannonMuzzle,
    FxChargeMuzzleFlash = EffectTemplate.SChronotronCannonMuzzleCharge,
}

---@class SDFChronotronCannonOverChargeWeapon : OverchargeWeapon
SDFChronotronCannonOverChargeWeapon = Class(OverchargeWeapon) {
    FxMuzzleFlash = EffectTemplate.SChronotronCannonOverChargeMuzzle,
    DesiredWeaponLabel = 'ChronotronCannon'
}

-- Units: XSL0301
---@class SDFLightChronotronCannonWeapon : DefaultProjectileWeapon
SDFLightChronotronCannonWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SLightChronotronCannonMuzzleFlash,
}

---@class SDFLightChronotronCannonOverchargeWeapon : OverchargeWeapon
SDFLightChronotronCannonOverchargeWeapon = Class(OverchargeWeapon) {
    FxMuzzleFlash = EffectTemplate.SLightChronotronCannonOverChargeMuzzleFlash,
    DesiredWeaponLabel = 'LightChronatronCannon'
}

---@class SAAShleoCannonWeapon : DefaultProjectileWeapon
SAAShleoCannonWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SShleoCannonMuzzleFlash,
}

---@class SAAOlarisCannonWeapon : DefaultProjectileWeapon
SAAOlarisCannonWeapon = Class(DefaultProjectileWeapon) {
    FxChargeEffects = EffectTemplate.SOlarisCannonMuzzleCharge,
    FxMuzzleFlash = EffectTemplate.SOlarisCannonMuzzleFlash01,
}

---@class SAALosaareAutoCannonWeapon : DefaultProjectileWeapon
SAALosaareAutoCannonWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SLosaareAutoCannonMuzzleFlash,
}
---@class SAALosaareAutoCannonWeaponAirUnit : DefaultProjectileWeapon
SAALosaareAutoCannonWeaponAirUnit = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SLosaareAutoCannonMuzzleFlashAirUnit,
}
---@class SAALosaareAutoCannonWeaponSeaUnit : DefaultProjectileWeapon
SAALosaareAutoCannonWeaponSeaUnit = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SLosaareAutoCannonMuzzleFlashSeaUnit,
}


---@class SDFAjelluAntiTorpedoDefense : DefaultProjectileWeapon
SDFAjelluAntiTorpedoDefense = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SDFAjelluAntiTorpedoLaunch01,
}

---@class SIFThunthoCannonWeapon : DefaultProjectileWeapon
SIFThunthoCannonWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SThunderStormCannonMuzzleFlash,
}

---@class SIFSuthanusArtilleryCannon : DefaultProjectileWeapon
SIFSuthanusArtilleryCannon = Class(DefaultProjectileWeapon) {
    FxChargeMuzzleFlash = EffectTemplate.SRifterArtilleryChargeMuzzleFlash,
    FxMuzzleFlash = EffectTemplate.SRifterArtilleryMuzzleFlash,
}

---@class SIFSuthanusMobileArtilleryCannon : DefaultProjectileWeapon
SIFSuthanusMobileArtilleryCannon = Class(DefaultProjectileWeapon) {
    FxChargeMuzzleFlash = EffectTemplate.SRifterMobileArtilleryChargeMuzzleFlash,
    FxMuzzleFlash = EffectTemplate.SRifterMobileArtilleryMuzzleFlash,
}

---@class SDFExperimentalPhasonLaser : DefaultBeamWeapon
SDFExperimentalPhasonLaser = Class(DefaultBeamWeapon) {
    BeamType = CollisionBeamFile.ExperimentalPhasonLaserCollisionBeam,
    FxMuzzleFlash = {},
    FxChargeMuzzleFlash = {},
    FxUpackingChargeEffects = EffectTemplate.SChargeExperimentalPhasonLaser,
    FxUpackingChargeEffectScale = 1,

    PlayFxWeaponUnpackSequence = function(self)
        if not self.ContBeamOn then
            local army = self.unit.Army
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

---@class SDFUnstablePhasonBeam : DefaultBeamWeapon
SDFUnstablePhasonBeam = Class(DefaultBeamWeapon) {
    BeamType = CollisionBeamFile.UnstablePhasonLaserCollisionBeam,
    FxMuzzleFlash = {},
    FxChargeMuzzleFlash = {}, --------EffectTemplate.SExperimentalUnstablePhasonLaserMuzzle01,
    FxUpackingChargeEffects = EffectTemplate.CMicrowaveLaserCharge01,
    FxUpackingChargeEffectScale = 1,
}

---@class SDFUltraChromaticBeamGenerator : DefaultBeamWeapon
SDFUltraChromaticBeamGenerator = Class(DefaultBeamWeapon) {
    BeamType = CollisionBeamFile.UltraChromaticBeamGeneratorCollisionBeam,
    FxMuzzleFlash = {},
    FxChargeMuzzleFlash = {},
    FxUpackingChargeEffects = EffectTemplate.SChargeUltraChromaticBeamGenerator,
    FxUpackingChargeEffectScale = 1,

    PlayFxWeaponUnpackSequence = function(self)
        if not self.ContBeamOn then
            local army = self.unit.Army
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

---@class SDFUltraChromaticBeamGenerator02 : SDFUltraChromaticBeamGenerator
SDFUltraChromaticBeamGenerator02 = Class(SDFUltraChromaticBeamGenerator) {
    BeamType = CollisionBeamFile.UltraChromaticBeamGeneratorCollisionBeam02,
}

---@class SLaanseMissileWeapon : DefaultProjectileWeapon
SLaanseMissileWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SLaanseMissleMuzzleFlash,
}

---@class SExperimentalStrategicMissileWeapon : DefaultProjectileWeapon
SExperimentalStrategicMissileWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SExperimentalStrategicMissileMuzzleFlash,
}

---@class SAMElectrumMissileDefense : DefaultProjectileWeapon
SAMElectrumMissileDefense = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SElectrumMissleDefenseMuzzleFlash,
}

---@class SDFBombOtheWeapon : DefaultProjectileWeapon
SDFBombOtheWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SOtheBombMuzzleFlash,
}

---@class SIFBombZhanaseeWeapon : DefaultProjectileWeapon
SIFBombZhanaseeWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SZhanaseeMuzzleFlash01,
}

---@class SDFHeavyQuarnonCannon : DefaultProjectileWeapon
SDFHeavyQuarnonCannon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SHeavyQuarnonCannonMuzzleFlash,
}

---@class SDFSniperShotNormalMode : DefaultProjectileWeapon
SDFSniperShotNormalMode = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SDFSniperShotNormalMuzzleFlash,
}

---@class SDFSniperShotSniperMode : DefaultProjectileWeapon
SDFSniperShotSniperMode = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SDFSniperShotMuzzleFlash,
}

---@class SB0OhwalliExperimentalStrategicBombWeapon : DefaultProjectileWeapon
SB0OhwalliExperimentalStrategicBombWeapon = Class(DefaultProjectileWeapon) {
}

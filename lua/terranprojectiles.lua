------------------------------------------------------------
--
--  File     : /lua/terranprojectiles.lua
--  Author(s): John Comes, Gordon Duclos, Matt Vainio
--
--  Summary  :
--
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------

--------------------------------------------------------------------------
--  TERRAN PROJECTILES SCRIPTS
--------------------------------------------------------------------------
local Projectile = import("/lua/sim/projectile.lua").Projectile
local DefaultProjectileFile = import("/lua/sim/defaultprojectiles.lua")
local EmitterProjectile = DefaultProjectileFile.EmitterProjectile
local OnWaterEntryEmitterProjectile = DefaultProjectileFile.OnWaterEntryEmitterProjectile
local SingleBeamProjectile = DefaultProjectileFile.SingleBeamProjectile
local SinglePolyTrailProjectile = DefaultProjectileFile.SinglePolyTrailProjectile
local MultiPolyTrailProjectile = DefaultProjectileFile.MultiPolyTrailProjectile
local SingleCompositeEmitterProjectile = DefaultProjectileFile.SingleCompositeEmitterProjectile
local Explosion = import("/lua/defaultexplosions.lua")
local EffectTemplate = import("/lua/effecttemplates.lua")
local DepthCharge = import("/lua/defaultantiprojectile.lua").DepthCharge
local util = import("/lua/utilities.lua")
local NukeProjectile = DefaultProjectileFile.NukeProjectile
local RandomFloat = import("/lua/utilities.lua").GetRandomFloat

---@class TFragmentationGrenade : EmitterProjectile
TFragmentationGrenade = Class(EmitterProjectile) {
    FxImpactUnit = EffectTemplate.THeavyFragmentationGrenadeUnitHit,
    FxImpactLand = EffectTemplate.THeavyFragmentationGrenadeHit,
    FxImpactWater = EffectTemplate.THeavyFragmentationGrenadeHit,
    FxImpactNone = EffectTemplate.THeavyFragmentationGrenadeHit,
    FxImpactProp = EffectTemplate.THeavyFragmentationGrenadeUnitHit,
    FxImpactUnderWater = {},
    FxTrails= EffectTemplate.THeavyFragmentationGrenadeFxTrails,
    --PolyTrail= EffectTemplate.THeavyFragmentationGrenadePolyTrail,
}

---@class TIFMissileNuke : NukeProjectile, SingleBeamProjectile
TIFMissileNuke = Class(NukeProjectile, SingleBeamProjectile) {
    BeamName = '/effects/emitters/missile_exhaust_fire_beam_01_emit.bp',
    FxImpactUnit = {},
    FxImpactLand = {},
    FxImpactUnderWater = {},
}

---@class TIFTacticalNuke : EmitterProjectile
TIFTacticalNuke = Class(EmitterProjectile) {
    FxImpactUnit = {},
    FxImpactLand = {},
    FxImpactUnderWater = {},
}

----------------------------------------
-- UEF GINSU RAPID PULSE BEAM PROJECTILE
----------------------------------------
---@class TAAGinsuRapidPulseBeamProjectile : SingleBeamProjectile
TAAGinsuRapidPulseBeamProjectile = Class(SingleBeamProjectile) {
    BeamName = '/effects/emitters/laserturret_munition_beam_03_emit.bp',
    FxImpactUnit = EffectTemplate.TAAGinsuHitUnit,
    FxImpactProp = EffectTemplate.TAAGinsuHitUnit,
    FxImpactLand = EffectTemplate.TAAGinsuHitLand,
    FxImpactUnderWater = {},
}

--------------------------------------------------------------------------
--  TERRAN AA PROJECTILES
--------------------------------------------------------------------------
---@class TAALightFragmentationProjectile : SingleCompositeEmitterProjectile
TAALightFragmentationProjectile = Class(SingleCompositeEmitterProjectile) {
    BeamName = '/effects/emitters/antiair_munition_beam_01_emit.bp',
    PolyTrail = '/effects/emitters/default_polytrail_01_emit.bp',
    PolyTrailOffset = 0,
    FxTrails = {'/effects/emitters/terran_flack_fxtrail_01_emit.bp'},
    FxImpactAirUnit = EffectTemplate.TFragmentationShell01,
    FxImpactNone = EffectTemplate.TFragmentationShell01,
    FxImpactUnderWater = {},
}

--------------------------------------------------------------------------
--  TERRAN ANTIMATTER ARTILLERY PROJECTILES
--------------------------------------------------------------------------
---@class TArtilleryAntiMatterProjectile : SinglePolyTrailProjectile
TArtilleryAntiMatterProjectile = Class(SinglePolyTrailProjectile) {
    FxImpactTrajectoryAligned = false,
    PolyTrail = '/effects/emitters/antimatter_polytrail_01_emit.bp',
    PolyTrailOffset = 0,

    -- Hit Effects
    FxImpactUnit = EffectTemplate.TAntiMatterShellHit01,
    FxImpactProp = EffectTemplate.TAntiMatterShellHit01,
    FxImpactLand = EffectTemplate.TAntiMatterShellHit01,
    FxLandHitScale = 1,
    FxImpactUnderWater = {},
}

---@class TArtilleryAntiMatterProjectile02 : TArtilleryAntiMatterProjectile
TArtilleryAntiMatterProjectile02 = Class(TArtilleryAntiMatterProjectile) {
    PolyTrail = '/effects/emitters/default_polytrail_07_emit.bp',

    -- Hit Effects
    FxImpactUnit = EffectTemplate.TAntiMatterShellHit02,
    FxImpactProp = EffectTemplate.TAntiMatterShellHit02,
    FxImpactLand = EffectTemplate.TAntiMatterShellHit02,
}

---@class TArtilleryAntiMatterSmallProjectile : TArtilleryAntiMatterProjectile02
TArtilleryAntiMatterSmallProjectile = Class(TArtilleryAntiMatterProjectile02) {
    FxLandHitScale = 0.5,
    FxUnitHitScale = 0.5,
    FxSplatScale = 6,
}

--------------------------------------------------------------------------
--  TERRAN ARTILLERY PROJECTILES
--------------------------------------------------------------------------
---@class TArtilleryProjectile : EmitterProjectile
TArtilleryProjectile = Class(EmitterProjectile) {
    FxImpactTrajectoryAligned = false,
    FxTrails = {'/effects/emitters/mortar_munition_01_emit.bp',},
    FxImpactUnit = EffectTemplate.TPlasmaCannonHeavyHitUnit01,
    FxImpactProp = EffectTemplate.TPlasmaCannonHeavyHitUnit01,
    FxImpactLand = EffectTemplate.TPlasmaCannonHeavyHit01,
}
---@class TArtilleryProjectilePolytrail : SinglePolyTrailProjectile
TArtilleryProjectilePolytrail = Class(SinglePolyTrailProjectile) {
    FxImpactUnit = EffectTemplate.TPlasmaCannonHeavyHitUnit01,
    FxImpactProp = EffectTemplate.TPlasmaCannonHeavyHitUnit01,
    FxImpactLand = EffectTemplate.TPlasmaCannonHeavyHit01,
}

--------------------------------------------------------------------------
--  TERRAN SHIP CANNON PROJECTILES
--------------------------------------------------------------------------
---@class TCannonSeaProjectile : SingleBeamProjectile
TCannonSeaProjectile = Class(SingleBeamProjectile) {
    BeamName = '/effects/emitters/cannon_munition_ship_beam_01_emit.bp',
    FxImpactUnderWater = {},
}

--------------------------------------------------------------------------
--  TERRAN TANK CANNON PROJECTILES
--------------------------------------------------------------------------
---@class TCannonTankProjectile : SingleBeamProjectile
TCannonTankProjectile = Class(SingleBeamProjectile) {
    BeamName = '/effects/emitters/cannon_munition_tank_beam_01_emit.bp',
    FxImpactUnderWater = {},
}

--------------------------------------------------------------------------
--  TERRAN DEPTH CHARGE PROJECTILES
--------------------------------------------------------------------------
---@class TDepthChargeProjectile : OnWaterEntryEmitterProjectile
TDepthChargeProjectile = Class(OnWaterEntryEmitterProjectile) {
    FxInitial = {},
    FxTrails = {'/effects/emitters/torpedo_underwater_wake_01_emit.bp',},
    TrailDelay = 0,

    -- Hit Effects
    FxImpactLand = {},
    FxUnitHitScale = 1.25,
    FxImpactUnit = EffectTemplate.TTorpedoHitUnit01,
    FxImpactProp = EffectTemplate.TTorpedoHitUnit01,
    FxImpactUnderWater = EffectTemplate.TTorpedoHitUnit01,
    FxImpactProjectile = EffectTemplate.TTorpedoHitUnit01,
    FxImpactNone = {},
    FxEnterWater= EffectTemplate.WaterSplash01,

    OnCreate = function(self, inWater)
        OnWaterEntryEmitterProjectile.OnCreate(self)
        self:TrackTarget(false)
    end,

    OnEnterWater = function(self)
        OnWaterEntryEmitterProjectile.OnEnterWater(self)

        self:TrackTarget(false)
        self:StayUnderwater(true)
        -- self:SetTurnRate(0)
        -- self:SetMaxSpeed(1)
        -- self:SetVelocity(0, -0.25, 0)
        -- self:SetVelocity(0.25)
    end,

    AddDepthCharge = function(self, tbl)
        if not tbl then return end
        if not tbl.Radius then return end
        self.MyDepthCharge = DepthCharge {
            Owner = self,
            Radius = tbl.Radius or 10,
        }
        self.Trash:Add(self.MyDepthCharge)
    end,
}



--------------------------------------------------------------------------
--  TERRAN GAUSS CANNON PROJECTILES
--------------------------------------------------------------------------
---@class TDFGeneralGaussCannonProjectile : MultiPolyTrailProjectile
TDFGeneralGaussCannonProjectile = Class(MultiPolyTrailProjectile) {
    FxTrails = {},
    PolyTrails = EffectTemplate.TGaussCannonPolyTrail,
    PolyTrailOffset = {0,0},
    FxTrailOffset = 0,
    FxImpactUnderWater = {},
}

---@class TDFGaussCannonProjectile : TDFGeneralGaussCannonProjectile
TDFGaussCannonProjectile = Class(TDFGeneralGaussCannonProjectile) { -- (UEB2301) UEF Triad and (UES0103) UEF Frigate and (UES0202) UEF Cruiser and (UEl0201) UEF Striker and (UEL0202) UEF Pillar
    FxImpactUnit = EffectTemplate.TGaussCannonHitUnit01,
    FxImpactProp = EffectTemplate.TGaussCannonHitUnit01,
    FxImpactLand = EffectTemplate.TGaussCannonHitLand01,
}

---@class TDFMediumShipGaussCannonProjectile : TDFGeneralGaussCannonProjectile
TDFMediumShipGaussCannonProjectile = Class(TDFGeneralGaussCannonProjectile) { -- (UES0201) UEF Destroyer
    FxImpactTrajectoryAligned = false,
    FxImpactUnit = EffectTemplate.TMediumShipGaussCannonHitUnit01,
    FxImpactProp = EffectTemplate.TMediumShipGaussCannonHit01,
    FxImpactLand = EffectTemplate.TMediumShipGaussCannonHit01,
}

---@class TDFBigShipGaussCannonProjectile : TDFGeneralGaussCannonProjectile
TDFBigShipGaussCannonProjectile = Class(TDFGeneralGaussCannonProjectile) { -- UES0302 (UEF Battleship)
    FxImpactTrajectoryAligned = false,
    FxImpactUnit = EffectTemplate.TShipGaussCannonHitUnit01,
    FxImpactProp = EffectTemplate.TShipGaussCannonHit01,
    FxImpactLand = EffectTemplate.TShipGaussCannonHit01,
    OnImpact = function(self, targetType, targetEntity)
        MultiPolyTrailProjectile.OnImpact(self, targetType, targetEntity)

        -- make it shake :)
        self:ShakeCamera( 20, 1, 0, 1 )
    end,
}

---@class TDFMediumLandGaussCannonProjectile : TDFGeneralGaussCannonProjectile
TDFMediumLandGaussCannonProjectile = Class(TDFGeneralGaussCannonProjectile) { -- Triad (T2 PD)
    FxImpactTrajectoryAligned = false,
    FxImpactUnit = EffectTemplate.TMediumLandGaussCannonHitUnit01,
    FxImpactProp = EffectTemplate.TMediumLandGaussCannonHit01,
    FxImpactLand = EffectTemplate.TMediumLandGaussCannonHit01,
}

---@class TDFBigLandGaussCannonProjectile : TDFGeneralGaussCannonProjectile
TDFBigLandGaussCannonProjectile = Class(TDFGeneralGaussCannonProjectile) { -- Fatboy
    FxImpactTrajectoryAligned = false,
    FxImpactUnit = EffectTemplate.TBigLandGaussCannonHitUnit01,
    FxImpactProp = EffectTemplate.TBigLandGaussCannonHit01,
    FxImpactLand = EffectTemplate.TBigLandGaussCannonHit01,
}

--------------------------------------------------------------------------
--  TERRAN HEAVY PLASMA CANNON PROJECTILES
--------------------------------------------------------------------------
---@class THeavyPlasmaCannonProjectile : MultiPolyTrailProjectile
THeavyPlasmaCannonProjectile = Class(MultiPolyTrailProjectile) { -- SACU, titan, T3 gunship and T3 transport
    FxTrails = EffectTemplate.TPlasmaCannonHeavyMunition,
    RandomPolyTrails = 1,
    PolyTrailOffset = {0,0,0},
    PolyTrails = EffectTemplate.TPlasmaCannonHeavyPolyTrails,
    FxImpactUnit = EffectTemplate.TPlasmaCannonHeavyHitUnit01,
    FxImpactProp = EffectTemplate.TPlasmaCannonHeavyHitUnit01,
    FxImpactLand = EffectTemplate.TPlasmaCannonHeavyHit01,
}


--------------------------------
--  UEF SMALL YIELD NUCLEAR BOMB
--------------------------------
---@class TIFSmallYieldNuclearBombProjectile : EmitterProjectile
TIFSmallYieldNuclearBombProjectile = Class(EmitterProjectile) { -- strategic bomber
    -- FxTrails = {},
    -- FxImpactUnit = EffectTemplate.TSmallYieldNuclearBombHit01,
    -- FxImpactProp = EffectTemplate.TSmallYieldNuclearBombHit01,
    -- FxImpactLand = EffectTemplate.TSmallYieldNuclearBombHit01,
    -- FxImpactUnderWater = {},

    FxImpactTrajectoryAligned = false,
    PolyTrail = '/effects/emitters/antimatter_polytrail_01_emit.bp',
    PolyTrailOffset = 0,

    -- Hit Effects
    FxImpactUnit = EffectTemplate.TAntiMatterShellHit01,
    FxImpactProp = EffectTemplate.TAntiMatterShellHit01,
    FxImpactLand = EffectTemplate.TAntiMatterShellHit01,
    FxLandHitScale = 1,
    FxImpactUnderWater = {},
}

--------------------------------------------------------------------------
--  TERRAN BOT LASER PROJECTILES
--------------------------------------------------------------------------
---@class TLaserBotProjectile : MultiPolyTrailProjectile
TLaserBotProjectile = Class(MultiPolyTrailProjectile) { -- ACU
    PolyTrails = EffectTemplate.TLaserPolytrail01,
    PolyTrailOffset = {0,0,0},
    FxTrails = EffectTemplate.TLaserFxtrail01,
    -- BeamName = '/effects/emitters/laserturret_munition_beam_03_emit.bp',
    FxImpactUnit = EffectTemplate.TLaserHitUnit02,
    FxImpactProp = EffectTemplate.TLaserHitUnit02,
    FxImpactLand = EffectTemplate.TLaserHitLand02,
    FxImpactUnderWater = {},
}

--------------------------------------------------------------------------
--  TERRAN LASER PROJECTILES
--------------------------------------------------------------------------
---@class TLaserProjectile : SingleBeamProjectile
TLaserProjectile = Class(SingleBeamProjectile) {
    BeamName = '/effects/emitters/laserturret_munition_beam_02_emit.bp',
    FxImpactUnit = EffectTemplate.TLaserHitUnit01,
    FxImpactProp = EffectTemplate.TLaserHitUnit01,
    FxImpactLand = EffectTemplate.TLaserHitLand01,
    FxImpactUnderWater = {},
}

--------------------------------------------------------------------------
--  TERRAN MACHINE GUN SHELLS
--------------------------------------------------------------------------
---@class TMachineGunProjectile : SinglePolyTrailProjectile
TMachineGunProjectile = Class(SinglePolyTrailProjectile) {
    PolyTrail = EffectTemplate.TMachineGunPolyTrail,
    FxTrails = {},
    FxImpactUnit = {
        '/effects/emitters/gauss_cannon_muzzle_flash_01_emit.bp',
        '/effects/emitters/flash_05_emit.bp',
    },
    FxImpactProp = {
        '/effects/emitters/gauss_cannon_muzzle_flash_01_emit.bp',
        '/effects/emitters/flash_05_emit.bp',
    },
    FxImpactLand = {
        '/effects/emitters/gauss_cannon_muzzle_flash_01_emit.bp',
        '/effects/emitters/flash_05_flat_emit.bp',
    },
}


--------------------------------------------------------------------------
--  TERRAN AA MISSILE PROJECTILES - Air Targets
--------------------------------------------------------------------------
---@class TMissileAAProjectile : EmitterProjectile
TMissileAAProjectile = Class(EmitterProjectile) {
    -- Emitter Values
    FxInitial = {},
    TrailDelay = 1,
    FxTrails = {'/effects/emitters/missile_sam_munition_trail_01_emit.bp',},
    FxTrailOffset = -0.5,

    FxAirUnitHitScale = 0.4,
    FxLandHitScale = 0.4,
    FxUnitHitScale = 0.4,
    FxPropHitScale = 0.4,
    FxImpactUnit = EffectTemplate.TMissileHit02,
    FxImpactAirUnit = EffectTemplate.TMissileHit02,
    FxImpactProp = EffectTemplate.TMissileHit02,
    FxImpactLand = EffectTemplate.TMissileHit02,
    FxImpactUnderWater = {},
}

---@class TAntiNukeInterceptorProjectile : SingleBeamProjectile
TAntiNukeInterceptorProjectile = Class(SingleBeamProjectile) {
    BeamName = '/effects/emitters/missile_exhaust_fire_beam_02_emit.bp',
    FxTrails = EffectTemplate.TMissileExhaust03,

    FxImpactUnit = EffectTemplate.TMissileHit01,
    FxImpactProp = EffectTemplate.TMissileHit01,
    FxImpactLand = EffectTemplate.TMissileHit01,
    FxImpactProjectile = EffectTemplate.TMissileHit01,
    FxProjectileHitScale = 5,
    FxImpactUnderWater = {},
}


--------------------------------------------------------------------------
--  TERRAN CRUISE MISSILE PROJECTILES - Surface Targets
--------------------------------------------------------------------------
---@class TMissileCruiseProjectile : SingleBeamProjectile
TMissileCruiseProjectile = Class(SingleBeamProjectile) {
    DestroyOnImpact = false,
    FxTrails = EffectTemplate.TMissileExhaust02,
    FxTrailOffset = -1,
    BeamName = '/effects/emitters/missile_munition_exhaust_beam_01_emit.bp',

    FxImpactUnit = EffectTemplate.TMissileHit01,
    FxImpactLand = EffectTemplate.TMissileHit01,
    FxImpactProp = EffectTemplate.TMissileHit01,
    FxImpactUnderWater = {},
}

---@class TMissileCruiseProjectile02 : SingleBeamProjectile
TMissileCruiseProjectile02 = Class(SingleBeamProjectile) {
    FxImpactTrajectoryAligned = false,
    DestroyOnImpact = false,
    FxTrails = EffectTemplate.TMissileExhaust02,
    FxTrailOffset = -1,
    BeamName = '/effects/emitters/missile_munition_exhaust_beam_01_emit.bp',

    FxImpactUnit = EffectTemplate.TShipGaussCannonHitUnit02,
    FxImpactProp = EffectTemplate.TShipGaussCannonHit02,
    FxImpactLand = EffectTemplate.TShipGaussCannonHit02,
    FxImpactUnderWater = {},
}

--------------------------------------------------------------------------
--  TERRAN SUB-LAUNCHED CRUISE MISSILE PROJECTILES
--------------------------------------------------------------------------
---@class TMissileCruiseSubProjectile : SingleBeamProjectile
TMissileCruiseSubProjectile = Class(SingleBeamProjectile) {
    FxExitWaterEmitter = EffectTemplate.TIFCruiseMissileLaunchExitWater,
    FxTrailOffset = -0.35,

    -- TRAILS
    FxTrails = EffectTemplate.TMissileExhaust02,
    BeamName = '/effects/emitters/missile_munition_exhaust_beam_01_emit.bp',

    -- Hit Effects
    FxImpactUnit = EffectTemplate.TMissileHit01,
    FxImpactLand = EffectTemplate.TMissileHit01,
    FxImpactProp = EffectTemplate.TMissileHit01,
    FxImpactUnderWater = {},
}

--------------------------------------------------------------------------
--  TERRAN MISSILE PROJECTILES - General Purpose
--------------------------------------------------------------------------
---@class TMissileProjectile : SingleBeamProjectile
TMissileProjectile = Class(SingleBeamProjectile) {
    FxTrails = {'/effects/emitters/missile_munition_trail_01_emit.bp',},
    FxTrailOffset = -1,
    BeamName = '/effects/emitters/missile_munition_exhaust_beam_01_emit.bp',

    FxImpactUnit = EffectTemplate.TMissileHit01,
    FxImpactProp = EffectTemplate.TMissileHit01,
    FxImpactLand = EffectTemplate.TMissileHit01,
    FxImpactUnderWater = {},
}

--------------------------------------------------------------------------
--  TERRAN NAPALM CARPET BOMB
--------------------------------------------------------------------------
---@class TNapalmCarpetBombProjectile : SinglePolyTrailProjectile
TNapalmCarpetBombProjectile = Class(SinglePolyTrailProjectile) {
    FxTrails = {},

    FxImpactTrajectoryAligned = false,

    -- Hit Effects
    FxImpactUnit = EffectTemplate.TNapalmCarpetBombHitLand01,
    FxImpactProp = EffectTemplate.TNapalmCarpetBombHitLand01,
    FxImpactLand = EffectTemplate.TNapalmCarpetBombHitLand01,
    FxImpactWater = EffectTemplate.TNapalmHvyCarpetBombHitWater01,
    FxImpactUnderWater = {},
    PolyTrail = '/effects/emitters/default_polytrail_01_emit.bp',
}

--------------------------------------------------------------------------
--  TERRAN HEAVY NAPALM CARPET BOMB
--------------------------------------------------------------------------
---@class TNapalmHvyCarpetBombProjectile : SinglePolyTrailProjectile
TNapalmHvyCarpetBombProjectile = Class(SinglePolyTrailProjectile) {
    FxTrails = {},

    FxImpactTrajectoryAligned = false,

    -- Hit Effects
    FxImpactUnit = EffectTemplate.TNapalmHvyCarpetBombHitLand01,
    FxImpactProp = EffectTemplate.TNapalmHvyCarpetBombHitLand01,
    FxImpactLand = EffectTemplate.TNapalmHvyCarpetBombHitLand01,
    FxImpactWater = EffectTemplate.TNapalmHvyCarpetBombHitLand01,
    FxImpactShield = EffectTemplate.TNapalmHvyCarpetBombHitLand01,
    FxImpactUnderWater = {},
    
    PolyTrail = '/effects/emitters/default_polytrail_01_emit.bp',
}


--------------------------------------------------------------------------
--  TERRAN PLASMA CANNON PROJECTILES
--------------------------------------------------------------------------
---@class TPlasmaCannonProjectile : SinglePolyTrailProjectile
TPlasmaCannonProjectile = Class(SinglePolyTrailProjectile) {
    FxTrails = EffectTemplate.TPlasmaCannonLightMunition,
    PolyTrailOffset = 0,
    PolyTrail = EffectTemplate.TPlasmaCannonLightPolyTrail,
    FxImpactUnit = EffectTemplate.TPlasmaCannonLightHitUnit01,
    FxImpactProp = EffectTemplate.TPlasmaCannonLightHitUnit01,
    FxImpactLand = EffectTemplate.TPlasmaCannonLightHitLand01,
}

--------------------------------------------------------------------------
--  TERRAN RAIL GUN PROJECTILES
--------------------------------------------------------------------------
---@class TRailGunProjectile : SinglePolyTrailProjectile
TRailGunProjectile = Class(SinglePolyTrailProjectile) {
    -- FxTrails = {'/effects/emitters/railgun_munition_trail_02_emit.bp' },
    PolyTrail = '/effects/emitters/railgun_polytrail_01_emit.bp',
    FxTrailScale = 1,
    FxTrailOffset = 0,
    FxImpactUnderWater = {},
    FxImpactUnit = EffectTemplate.TRailGunHitGround01,
    FxImpactProp = EffectTemplate.TRailGunHitGround01,
    FxImpactAirUnit = EffectTemplate.TRailGunHitAir01,
}

--------------------------------------------------------------------------
--  TERRAN PHALANX PROJECTILES
--------------------------------------------------------------------------
---@class TShellPhalanxProjectile : MultiPolyTrailProjectile
TShellPhalanxProjectile = Class(MultiPolyTrailProjectile) {
    PolyTrails = EffectTemplate.TPhalanxGunPolyTrails,
    PolyTrailOffset = EffectTemplate.TPhalanxGunPolyTrailsOffsets,
    FxImpactUnit = EffectTemplate.TRiotGunHitUnit01,
    FxImpactProp = EffectTemplate.TRiotGunHitUnit01,
    FxImpactNone = EffectTemplate.FireCloudSml01,
    FxImpactLand = EffectTemplate.TRiotGunHit01,
    FxImpactUnderWater = {},
    FxImpactProjectile = EffectTemplate.TMissileHit02,
    FxProjectileHitScale = 0.7,
}

--------------------------------------------------------------------------
--  TERRAN RIOT PROJECTILES
--------------------------------------------------------------------------
---@class TShellRiotProjectile : MultiPolyTrailProjectile
TShellRiotProjectile = Class(MultiPolyTrailProjectile) {
    PolyTrails = EffectTemplate.TRiotGunPolyTrails,
    PolyTrailOffset = EffectTemplate.TRiotGunPolyTrailsOffsets,
    FxTrails = EffectTemplate.TRiotGunMunition01,
    RandomPolyTrails = 1,
    FxImpactUnit = EffectTemplate.TRiotGunHitUnit01,
    FxImpactProp = EffectTemplate.TRiotGunHitUnit01,
    FxImpactLand = EffectTemplate.TRiotGunHit01,
    FxImpactUnderWater = {},
}

---@class TShellRiotProjectileLand : MultiPolyTrailProjectile
TShellRiotProjectileLand = Class(MultiPolyTrailProjectile) {
    PolyTrails = EffectTemplate.TRiotGunPolyTrailsTank,
    PolyTrailOffset = EffectTemplate.TRiotGunPolyTrailsOffsets,
    FxTrails = {},
    RandomPolyTrails = 1,
    FxImpactUnit = EffectTemplate.TRiotGunHitUnit02,
    FxImpactProp = EffectTemplate.TRiotGunHitUnit02,
    FxImpactLand = EffectTemplate.TRiotGunHit02,
    FxImpactUnderWater = {},
}

---@class TShellRiotProjectileLand02 : TShellRiotProjectileLand
TShellRiotProjectileLand02 = Class(TShellRiotProjectileLand) {
    PolyTrails = EffectTemplate.TRiotGunPolyTrailsEngineer,
}

--------------------------------------------------------------------------
--  TERRAN ABOVE WATER LAUNCHED TORPEDO
--------------------------------------------------------------------------
---@class TTorpedoShipProjectile : OnWaterEntryEmitterProjectile
TTorpedoShipProjectile = Class(OnWaterEntryEmitterProjectile) {
    FxInitial = {},
    FxTrails = {'/effects/emitters/torpedo_underwater_wake_01_emit.bp',},
    TrailDelay = 0,

    -- Hit Effects
    FxImpactLand = {},
    FxUnitHitScale = 1.25,
    FxImpactUnit = EffectTemplate.TTorpedoHitUnit01,
    FxImpactProp = EffectTemplate.TTorpedoHitUnit01,
    FxImpactUnderWater = EffectTemplate.TTorpedoHitUnitUnderwater01,
    FxImpactNone = {},
    FxEnterWater= EffectTemplate.WaterSplash01,

    OnCreate = function(self, inWater)
        OnWaterEntryEmitterProjectile.OnCreate(self)
        -- if we are starting in the water then immediately switch to tracking in water and
        -- create underwater trail effects
        if inWater == true then
            self:TrackTarget(true):StayUnderwater(true)
            self:OnEnterWater(self)
        end
    end,

    OnEnterWater = function(self)
        OnWaterEntryEmitterProjectile.OnEnterWater(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)

        self:TrackTarget(true)
        self:StayUnderwater(true)
        self:SetTurnRate(120)
        self:SetMaxSpeed(18)
        -- self:SetVelocity(0)
        self:ForkThread(self.MovementThread)
    end,

    MovementThread = function(self)
        WaitTicks(1)
        self:SetVelocity(3)
    end,
}
--------------------------------------------------------------------------
--  TERRAN SUB LAUNCHED TORPEDO
--------------------------------------------------------------------------
---@class TTorpedoSubProjectile : EmitterProjectile
TTorpedoSubProjectile = Class(EmitterProjectile) {
    FxTrails = {'/effects/emitters/torpedo_munition_trail_01_emit.bp',},
    FxImpactLand = {},
    FxUnitHitScale = 1.25,
    FxImpactUnit = EffectTemplate.TTorpedoHitUnit01,
    FxImpactProp = EffectTemplate.TTorpedoHitUnit01,
    FxImpactUnderWater = EffectTemplate.TTorpedoHitUnit01,
    FxImpactNone = {},
    OnCreate = function(self, inWater)
        self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)
        EmitterProjectile.OnCreate(self, inWater)
    end,
}

--------------------------------------------------------------------------
--  SC1X UEF BASE TEMPRORARY PROJECTILE
--------------------------------------------------------------------------
---@class TBaseTempProjectile : SinglePolyTrailProjectile
TBaseTempProjectile = Class(SinglePolyTrailProjectile) {
    FxImpactLand = EffectTemplate.AMissileHit01,
    FxImpactNone = EffectTemplate.AMissileHit01,
    FxImpactProjectile = EffectTemplate.ASaintImpact01,
    FxImpactProp = EffectTemplate.AMissileHit01,
    FxImpactUnderWater = {},
    FxImpactUnit = EffectTemplate.AMissileHit01,
    FxTrails = {
        '/effects/emitters/aeon_laser_fxtrail_01_emit.bp',
        '/effects/emitters/aeon_laser_fxtrail_02_emit.bp',
    },
    PolyTrail = '/effects/emitters/aeon_laser_trail_01_emit.bp',
}


--------------------------------------------------------------------------
--  UEF PLASMA GATLING CANNON PROJECTILE
--------------------------------------------------------------------------
---@class TGatlingPlasmaCannonProjectile : MultiPolyTrailProjectile
TGatlingPlasmaCannonProjectile = Class(MultiPolyTrailProjectile) {
    PolyTrailOffset = EffectTemplate.TPlasmaGatlingCannonPolyTrailsOffsets,
    FxImpactNone = EffectTemplate.TPlasmaGatlingCannonUnitHit,
    FxImpactUnit = EffectTemplate.TPlasmaGatlingCannonUnitHit,
    FxImpactProp = EffectTemplate.TPlasmaGatlingCannonUnitHit,
    FxImpactLand = EffectTemplate.TPlasmaGatlingCannonHit,
    FxImpactWater= EffectTemplate.TPlasmaGatlingCannonHit,
    RandomPolyTrails = 1,

    -- FxTrails = EffectTemplate.TPlasmaGatlingCannonFxTrails,
    PolyTrails = EffectTemplate.TPlasmaGatlingCannonPolyTrails,
}


--------------------------------------------------------------------------
--  UEF IONIZED PLASMA GATLING CANNON PROJECTILE
--------------------------------------------------------------------------
---@class TIonizedPlasmaGatlingCannon : SinglePolyTrailProjectile
TIonizedPlasmaGatlingCannon = Class(SinglePolyTrailProjectile) { -- percival
    FxImpactWater = EffectTemplate.TIonizedPlasmaGatlingCannonHit,
    FxImpactLand = EffectTemplate.TIonizedPlasmaGatlingCannonHit,
    FxImpactNone = EffectTemplate.TIonizedPlasmaGatlingCannonHit,
    FxImpactProp = EffectTemplate.TIonizedPlasmaGatlingCannonUnitHit,
    FxImpactUnit = EffectTemplate.TIonizedPlasmaGatlingCannonUnitHit,
    FxTrails = EffectTemplate.TIonizedPlasmaGatlingCannonFxTrails,
    PolyTrail = EffectTemplate.TIonizedPlasmaGatlingCannonPolyTrail,
    FxImpactProjectile = {},
    FxImpactUnderWater = {},
}


--------------------------------------------------------------------------
--  UEF HEAVY PLASMA GATLING CANNON PROJECTILE
--------------------------------------------------------------------------
---@class THeavyPlasmaGatlingCannon : SinglePolyTrailProjectile
THeavyPlasmaGatlingCannon = Class(SinglePolyTrailProjectile) { -- ravager
    FxImpactTrajectoryAligned = false,
    FxImpactUnit = EffectTemplate.THeavyPlasmaGatlingCannonHit,
    FxImpactProp = EffectTemplate.THeavyPlasmaGatlingCannonHit,
    FxImpactWater = EffectTemplate.THeavyPlasmaGatlingCannonHit,
    FxImpactLand = EffectTemplate.THeavyPlasmaGatlingCannonHit,
    FxImpactUnderWater = {},
    FxTrails = EffectTemplate.THeavyPlasmaGatlingCannonFxTrails,
    PolyTrail = EffectTemplate.THeavyPlasmaGatlingCannonPolyTrail,
}


-- this used to be the tri barelled hiro cannon.
---@class THiroLaser : SinglePolyTrailProjectile
THiroLaser = Class(SinglePolyTrailProjectile) {

    FxTrailOffset = 0,
    FxImpactUnit = EffectTemplate.THiroLaserUnitHit,
    FxImpactProp = EffectTemplate.THiroLaserHit,
    FxImpactLand = EffectTemplate.THiroLaserLandHit,
    FxImpactWater = EffectTemplate.THiroLaserLandHit,
    FxImpactUnderWater = {},

    FxTrails = EffectTemplate.THiroLaserFxtrails,
    PolyTrail = EffectTemplate.THiroLaserPolytrail,
}



------------------------------------------------------------
--  File     : /lua/terranprojectiles.lua
--  Author(s): John Comes, Gordon Duclos, Matt Vainio
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------
local DefaultProjectileFile = import("/lua/sim/defaultprojectiles.lua")
local EmitterProjectile = DefaultProjectileFile.EmitterProjectile
local OnWaterEntryEmitterProjectile = DefaultProjectileFile.OnWaterEntryEmitterProjectile
local SingleBeamProjectile = DefaultProjectileFile.SingleBeamProjectile
local SinglePolyTrailProjectile = DefaultProjectileFile.SinglePolyTrailProjectile
local MultiPolyTrailProjectile = DefaultProjectileFile.MultiPolyTrailProjectile
local SingleCompositeEmitterProjectile = DefaultProjectileFile.SingleCompositeEmitterProjectile
local EffectTemplate = import("/lua/effecttemplates.lua")
local DepthCharge = import("/lua/defaultantiprojectile.lua").DepthCharge
local NukeProjectile = DefaultProjectileFile.NukeProjectile

local DebrisComponent = import('/lua/sim/projectiles/components/DebrisComponent.lua').DebrisComponent
local TacticalMissileComponent = import('/lua/sim/DefaultProjectiles.lua').TacticalMissileComponent

---@class TFragmentationGrenade : EmitterProjectile
TFragmentationGrenade = ClassProjectile(EmitterProjectile) {
    FxImpactUnit = EffectTemplate.THeavyFragmentationGrenadeUnitHit,
    FxImpactLand = EffectTemplate.THeavyFragmentationGrenadeHit,
    FxImpactWater = EffectTemplate.THeavyFragmentationGrenadeHit,
    FxImpactNone = EffectTemplate.THeavyFragmentationGrenadeHit,
    FxImpactProp = EffectTemplate.THeavyFragmentationGrenadeUnitHit,
    FxTrails = EffectTemplate.THeavyFragmentationGrenadeFxTrails,
}

---@class TIFMissileNuke : NukeProjectile, SingleBeamProjectile
TIFMissileNuke = ClassProjectile(NukeProjectile, SingleBeamProjectile) {
    BeamName = '/effects/emitters/missile_exhaust_fire_beam_01_emit.bp',
}

---@class TIFTacticalNuke : EmitterProjectile
TIFTacticalNuke = ClassProjectile(EmitterProjectile) {}

--- UEF GINSU RAPID PULSE BEAM PROJECTILE
---@class TAAGinsuRapidPulseBeamProjectile : SingleBeamProjectile
TAAGinsuRapidPulseBeamProjectile = ClassProjectile(SingleBeamProjectile) {
    BeamName = '/effects/emitters/laserturret_munition_beam_03_emit.bp',
    FxImpactUnit = EffectTemplate.TAAGinsuHitUnit,
    FxImpactProp = EffectTemplate.TAAGinsuHitUnit,
    FxImpactAirUnit = EffectTemplate.TAAGinsuHitUnit,
    FxImpactLand = EffectTemplate.TAAGinsuHitLand,
}

---  TERRAN AA PROJECTILES
---@class TAALightFragmentationProjectile : SingleCompositeEmitterProjectile
TAALightFragmentationProjectile = ClassProjectile(SingleCompositeEmitterProjectile) {
    BeamName = '/effects/emitters/antiair_munition_beam_01_emit.bp',
    PolyTrail = '/effects/emitters/default_polytrail_01_emit.bp',
    PolyTrailOffset = 0,
    FxTrails = { '/effects/emitters/terran_flack_fxtrail_01_emit.bp' },
    FxImpactAirUnit = EffectTemplate.TFragmentationShell01,
    FxImpactNone = EffectTemplate.TFragmentationShell01,
}

---  TERRAN ANTIMATTER ARTILLERY PROJECTILES
---@class TArtilleryAntiMatterProjectile : SinglePolyTrailProjectile
TArtilleryAntiMatterProjectile = ClassProjectile(SinglePolyTrailProjectile) {
    FxImpactTrajectoryAligned = false,
    PolyTrail = '/effects/emitters/antimatter_polytrail_01_emit.bp',
    PolyTrailOffset = 0,
    FxImpactUnit = EffectTemplate.TAntiMatterShellHit01,
    FxImpactProp = EffectTemplate.TAntiMatterShellHit01,
    FxImpactLand = EffectTemplate.TAntiMatterShellHit01,
    FxLandHitScale = 1,
}

---  TERRAN ANTIMATTER ARTILLERY PROJECTILES
---@class TArtilleryAntiMatterProjectile02 : TArtilleryAntiMatterProjectile
TArtilleryAntiMatterProjectile02 = ClassProjectile(TArtilleryAntiMatterProjectile) {
    PolyTrail = '/effects/emitters/default_polytrail_07_emit.bp',
    FxImpactUnit = EffectTemplate.TAntiMatterShellHit02,
    FxImpactProp = EffectTemplate.TAntiMatterShellHit02,
    FxImpactLand = EffectTemplate.TAntiMatterShellHit02,
}

---  TERRAN ANTIMATTER ARTILLERY PROJECTILES
---@class TArtilleryAntiMatterSmallProjectile : TArtilleryAntiMatterProjectile02
TArtilleryAntiMatterSmallProjectile = ClassProjectile(TArtilleryAntiMatterProjectile02) {
    FxLandHitScale = 0.5,
    FxUnitHitScale = 0.5,
    FxSplatScale = 6,
}

---  TERRAN ARTILLERY PROJECTILES
---@class TArtilleryProjectile : EmitterProjectile
TArtilleryProjectile = ClassProjectile(EmitterProjectile) {
    FxImpactTrajectoryAligned = false,
    FxTrails = { '/effects/emitters/mortar_munition_01_emit.bp', },
    FxImpactUnit = EffectTemplate.TPlasmaCannonHeavyHitUnit01,
    FxImpactProp = EffectTemplate.TPlasmaCannonHeavyHitUnit01,
    FxImpactLand = EffectTemplate.TPlasmaCannonHeavyHit01,
}

---  TERRAN ARTILLERY PROJECTILES
---@class TArtilleryProjectilePolytrail : SinglePolyTrailProjectile
TArtilleryProjectilePolytrail = ClassProjectile(SinglePolyTrailProjectile) {
    FxImpactUnit = EffectTemplate.TPlasmaCannonHeavyHitUnit01,
    FxImpactProp = EffectTemplate.TPlasmaCannonHeavyHitUnit01,
    FxImpactLand = EffectTemplate.TPlasmaCannonHeavyHit01,
}

---  TERRAN SHIP CANNON PROJECTILES
---@class TCannonSeaProjectile : SingleBeamProjectile
TCannonSeaProjectile = ClassProjectile(SingleBeamProjectile) {
    BeamName = '/effects/emitters/cannon_munition_ship_beam_01_emit.bp',
}

---  TERRAN TANK CANNON PROJECTILES
---@class TCannonTankProjectile : SingleBeamProjectile
TCannonTankProjectile = ClassProjectile(SingleBeamProjectile) {
    BeamName = '/effects/emitters/cannon_munition_tank_beam_01_emit.bp',
}

---  TERRAN DEPTH CHARGE PROJECTILES
---@class TDepthChargeProjectile : OnWaterEntryEmitterProjectile
TDepthChargeProjectile = ClassProjectile(OnWaterEntryEmitterProjectile) {
    FxTrails = { '/effects/emitters/torpedo_underwater_wake_01_emit.bp', },
    TrailDelay = 0,
    FxUnitHitScale = 1.25,
    FxImpactUnit = EffectTemplate.TTorpedoHitUnit01,
    FxImpactProp = EffectTemplate.TTorpedoHitUnit01,
    FxImpactUnderWater = EffectTemplate.TTorpedoHitUnit01,
    FxImpactProjectile = EffectTemplate.TTorpedoHitUnit01,
    FxEnterWater = EffectTemplate.WaterSplash01,

    ---@param self TDepthChargeProjectile
    ---@param inWater? boolean
    OnCreate = function(self, inWater)
        OnWaterEntryEmitterProjectile.OnCreate(self)
        self:TrackTarget(false)
    end,

    ---@param self TDepthChargeProjectile
    OnEnterWater = function(self)
        OnWaterEntryEmitterProjectile.OnEnterWater(self)
        self:TrackTarget(false)
        self:StayUnderwater(true)
    end,
}

---  TERRAN GAUSS CANNON PROJECTILES
---@class TDFGeneralGaussCannonProjectile : MultiPolyTrailProjectile
TDFGeneralGaussCannonProjectile = ClassProjectile(MultiPolyTrailProjectile) {
    PolyTrails = EffectTemplate.TGaussCannonPolyTrail,
    PolyTrailOffset = { 0, 0 },
    FxTrailOffset = 0,
}

--- (UEB2301) UEF Triad and (UES0103) UEF Frigate and (UES0202) UEF Cruiser and (UEl0201) UEF Striker and (UEL0202) UEF Pillar
---@class TDFGaussCannonProjectile : TDFGeneralGaussCannonProjectile
TDFGaussCannonProjectile = ClassProjectile(TDFGeneralGaussCannonProjectile) {
    FxImpactUnit = EffectTemplate.TGaussCannonHitUnit01,
    FxImpactProp = EffectTemplate.TGaussCannonHitUnit01,
    FxImpactLand = EffectTemplate.TGaussCannonHitLand01,
    FxImpactWater = EffectTemplate.TGaussWaterSplash01,
    FxWaterHitScale = 0.75,
}

--- (UES0201) UEF Destroyer
---@class TDFMediumShipGaussCannonProjectile : TDFGeneralGaussCannonProjectile
TDFMediumShipGaussCannonProjectile = ClassProjectile(TDFGeneralGaussCannonProjectile) {
    FxImpactTrajectoryAligned = false,
    FxImpactUnit = EffectTemplate.TMediumShipGaussCannonHitUnit01,
    FxImpactProp = EffectTemplate.TMediumShipGaussCannonHit01,
    FxImpactLand = EffectTemplate.TMediumShipGaussCannonHit01,
}

--- UES0302 (UEF Battleship)
---@class TDFBigShipGaussCannonProjectile : TDFGeneralGaussCannonProjectile
TDFBigShipGaussCannonProjectile = ClassProjectile(TDFGeneralGaussCannonProjectile) {
    FxImpactTrajectoryAligned = false,
    FxImpactUnit = EffectTemplate.TShipGaussCannonHitUnit01,
    FxImpactProp = EffectTemplate.TShipGaussCannonHit01,
    FxImpactLand = EffectTemplate.TShipGaussCannonHit01,

    ---@param self TDFBigShipGaussCannonProjectile
    ---@param targetType string
    ---@param targetEntity Unit | Prop
    OnImpact = function(self, targetType, targetEntity)
        MultiPolyTrailProjectile.OnImpact(self, targetType, targetEntity)
        self:ShakeCamera(20, 1, 0, 1)
    end,
}

--- Triad (T2 PD)
---@class TDFMediumLandGaussCannonProjectile : TDFGeneralGaussCannonProjectile
TDFMediumLandGaussCannonProjectile = ClassProjectile(TDFGeneralGaussCannonProjectile) {
    FxImpactTrajectoryAligned = false,
    FxImpactUnit = EffectTemplate.TMediumLandGaussCannonHitUnit01,
    FxImpactProp = EffectTemplate.TMediumLandGaussCannonHit01,
    FxImpactLand = EffectTemplate.TMediumLandGaussCannonHit01,
}

--- Fatboy
---@class TDFBigLandGaussCannonProjectile : TDFGeneralGaussCannonProjectile
TDFBigLandGaussCannonProjectile = ClassProjectile(TDFGeneralGaussCannonProjectile) {
    FxImpactTrajectoryAligned = false,
    FxImpactUnit = EffectTemplate.TBigLandGaussCannonHitUnit01,
    FxImpactProp = EffectTemplate.TBigLandGaussCannonHit01,
    FxImpactLand = EffectTemplate.TBigLandGaussCannonHit01,
}

---  TERRAN HEAVY PLASMA CANNON PROJECTILES
--- SACU, titan, T3 gunship and T3 transport
---@class THeavyPlasmaCannonProjectile : MultiPolyTrailProjectile
THeavyPlasmaCannonProjectile = ClassProjectile(MultiPolyTrailProjectile) {
    FxTrails = EffectTemplate.TPlasmaCannonHeavyMunition,
    RandomPolyTrails = 1,
    PolyTrailOffset = { 0, 0, 0 },
    PolyTrails = EffectTemplate.TPlasmaCannonHeavyPolyTrails,
    FxImpactUnit = EffectTemplate.TPlasmaCannonHeavyHitUnit01,
    FxImpactProp = EffectTemplate.TPlasmaCannonHeavyHitUnit01,
    FxImpactLand = EffectTemplate.TPlasmaCannonHeavyHit01,
}

---  UEF SMALL YIELD NUCLEAR BOMB
--- strategic bomber
---@class TIFSmallYieldNuclearBombProjectile : EmitterProjectile
TIFSmallYieldNuclearBombProjectile = ClassProjectile(EmitterProjectile) {
    FxImpactTrajectoryAligned = false,
    PolyTrail = '/effects/emitters/antimatter_polytrail_01_emit.bp',
    PolyTrailOffset = 0,
    FxImpactUnit = EffectTemplate.TAntiMatterShellHit01,
    FxImpactProp = EffectTemplate.TAntiMatterShellHit01,
    FxImpactLand = EffectTemplate.TAntiMatterShellHit01,
    FxLandHitScale = 1,
}

---  TERRAN BOT LASER PROJECTILES
--- ACU
---@class TLaserBotProjectile : MultiPolyTrailProjectile
TLaserBotProjectile = ClassProjectile(MultiPolyTrailProjectile) {
    PolyTrails = EffectTemplate.TLaserPolytrail01,
    PolyTrailOffset = { 0, 0, 0 },
    FxTrails = EffectTemplate.TLaserFxtrail01,
    FxImpactUnit = EffectTemplate.TLaserHitUnit02,
    FxImpactProp = EffectTemplate.TLaserHitUnit02,
    FxImpactLand = EffectTemplate.TLaserHitLand02,
}

---  TERRAN LASER PROJECTILES
---@class TLaserProjectile : SingleBeamProjectile
TLaserProjectile = ClassProjectile(SingleBeamProjectile) {
    BeamName = '/effects/emitters/laserturret_munition_beam_02_emit.bp',
    FxImpactUnit = EffectTemplate.TLaserHitUnit01,
    FxImpactProp = EffectTemplate.TLaserHitUnit01,
    FxImpactLand = EffectTemplate.TLaserHitLand01,
}

---  TERRAN MACHINE GUN SHELLS
---@class TMachineGunProjectile : SinglePolyTrailProjectile
TMachineGunProjectile = ClassProjectile(SinglePolyTrailProjectile) {
    PolyTrail = EffectTemplate.TMachineGunPolyTrail,
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

---  TERRAN AA MISSILE PROJECTILES - Air Targets
---@class TMissileAAProjectile : EmitterProjectile
TMissileAAProjectile = ClassProjectile(EmitterProjectile) {
    TrailDelay = 1,
    FxTrails = { '/effects/emitters/missile_sam_munition_trail_01_emit.bp', },
    FxTrailOffset = -0.5,
    FxAirUnitHitScale = 0.4,
    FxLandHitScale = 0.4,
    FxUnitHitScale = 0.4,
    FxPropHitScale = 0.4,
    FxImpactUnit = EffectTemplate.TMissileHit02,
    FxImpactAirUnit = EffectTemplate.TMissileHit02,
    FxImpactProp = EffectTemplate.TMissileHit02,
    FxImpactLand = EffectTemplate.TMissileHit02,
}

---@class TAntiNukeInterceptorProjectile : SingleBeamProjectile
TAntiNukeInterceptorProjectile = ClassProjectile(SingleBeamProjectile) {
    BeamName = '/effects/emitters/missile_exhaust_fire_beam_02_emit.bp',
    FxTrails = EffectTemplate.TMissileExhaust03,
    FxImpactUnit = EffectTemplate.TMissileHit01,
    FxImpactProp = EffectTemplate.TMissileHit01,
    FxImpactLand = EffectTemplate.TMissileHit01,
    FxImpactProjectile = EffectTemplate.TMissileHit01,
    FxProjectileHitScale = 5,
}

---  TERRAN MISSILE PROJECTILES - General Purpose
---@class TMissileProjectile : SingleBeamProjectile, TacticalMissileComponent, DebrisComponent
TMissileProjectile = ClassProjectile(SingleBeamProjectile, TacticalMissileComponent, DebrisComponent) {
    DestroyOnImpact = false,
    FxTrails = EffectTemplate.TMissileExhaust02,
    FxTrailOffset = -1,
    BeamName = '/effects/emitters/missile_munition_exhaust_beam_01_emit.bp',
    FxImpactUnit = EffectTemplate.TMissileHit01,
    FxImpactLand = EffectTemplate.TMissileHit01,
    FxImpactProp = EffectTemplate.TMissileHit01,

    FxOnKilled = EffectTemplate.TMissileKilled01,
    FxOnKilledScale = 0.7,

    FxImpactNone = EffectTemplate.TMissileKilled01,
    FxNoneHitScale = 0.7,

    LaunchTicks = 12,
    LaunchTicksRange = 2,

    LaunchTurnRate = 6,
    LaunchTurnRateRange = 2,

    HeightDistanceFactor = 5.5,
    HeightDistanceFactorRange = 0.5,

    MinHeight = 10,
    MinHeightRange = 1,

    FinalBoostAngle = 50,
    FinalBoostAngleRange = 5,

    DebrisBlueprints = {
        '/effects/Entities/TacticalDebris01/TacticalDebris01_proj.bp',
        '/effects/Entities/TacticalDebris01/TacticalDebris01_proj.bp',
        '/effects/Entities/TacticalDebris02/TacticalDebris02_proj.bp',
    },

    OnCreate = function(self)
        SingleBeamProjectile.OnCreate(self)
        local blueprintPhysics = self.Blueprint.Physics
        local radius = 0.105 * (blueprintPhysics.MaxSpeed + blueprintPhysics.MaxSpeedRange)
        self:SetCollisionShape('Sphere', 0, 0, 0, radius)
    end,

    ---@param self TMissileProjectile
    ---@param instigator Unit
    ---@param type string
    ---@param overkillRatio number
    OnKilled = function(self, instigator, type, overkillRatio)
        SingleBeamProjectile.OnKilled(self, instigator, type, overkillRatio)

        self:CreateDebris()
        CreateLightParticle(self, -1, self.Army, 3, 6, 'flare_lens_add_02', 'ramp_fire_13')
    end,

    ---@param self TMissileProjectile
    ---@param targetType string
    ---@param targetEntity Prop|Unit
    OnImpact = function(self, targetType, targetEntity)
        SingleBeamProjectile.OnImpact(self, targetType, targetEntity)
        if targetType == 'None' or targetType == 'Air' then
            self:CreateDebris()
        end

        CreateLightParticle(self, -1, self.Army, 4, 4, 'flare_lens_add_02', 'ramp_fire_13')
    end,
}

---  TERRAN CRUISE MISSILE PROJECTILES - Surface Targets
---@class TMissileCruiseProjectile : TMissileProjectile
TMissileCruiseProjectile = ClassProjectile(TMissileProjectile) {
    DestroyOnImpact = false,
    FxTrails = EffectTemplate.TMissileExhaust02,
    FxTrailOffset = -1,
    BeamName = '/effects/emitters/missile_munition_exhaust_beam_01_emit.bp',
    FxImpactUnit = EffectTemplate.TMissileHit01,
    FxImpactLand = EffectTemplate.TMissileHit01,
    FxImpactProp = EffectTemplate.TMissileHit01,
}

---@class TMissileCruiseProjectile02 : TMissileProjectile
TMissileCruiseProjectile02 = ClassProjectile(TMissileProjectile) {
    FxImpactTrajectoryAligned = false,
    DestroyOnImpact = false,
    FxTrails = EffectTemplate.TMissileExhaust02,
    FxTrailOffset = -1,
    BeamName = '/effects/emitters/missile_munition_exhaust_beam_01_emit.bp',
    FxImpactUnit = EffectTemplate.TShipGaussCannonHitUnit02,
    FxImpactProp = EffectTemplate.TShipGaussCannonHit02,
    FxImpactLand = EffectTemplate.TShipGaussCannonHit02,
}

---  TERRAN SUB-LAUNCHED CRUISE MISSILE PROJECTILES
---@class TMissileCruiseSubProjectile : TMissileProjectile
TMissileCruiseSubProjectile = ClassProjectile(TMissileProjectile) {
    FxExitWaterEmitter = EffectTemplate.TIFCruiseMissileLaunchExitWater,
    FxTrailOffset = -0.35,
    FxTrails = EffectTemplate.TMissileExhaust02,
    BeamName = '/effects/emitters/missile_munition_exhaust_beam_01_emit.bp',
    FxImpactUnit = EffectTemplate.TMissileHit01,
    FxImpactLand = EffectTemplate.TMissileHit01,
    FxImpactProp = EffectTemplate.TMissileHit01,
}

---  TERRAN NAPALM CARPET BOMB
---@class TNapalmCarpetBombProjectile : SinglePolyTrailProjectile
TNapalmCarpetBombProjectile = ClassProjectile(SinglePolyTrailProjectile) {
    FxImpactTrajectoryAligned = false,
    FxImpactUnit = EffectTemplate.TNapalmCarpetBombHitLand01,
    FxImpactProp = EffectTemplate.TNapalmCarpetBombHitLand01,
    FxImpactLand = EffectTemplate.TNapalmCarpetBombHitLand01,
    FxImpactWater = EffectTemplate.TNapalmHvyCarpetBombHitWater01,
    PolyTrail = '/effects/emitters/default_polytrail_01_emit.bp',
}

---  TERRAN HEAVY NAPALM CARPET BOMB
---@class TNapalmHvyCarpetBombProjectile : SinglePolyTrailProjectile
TNapalmHvyCarpetBombProjectile = ClassProjectile(SinglePolyTrailProjectile) {
    FxImpactTrajectoryAligned = false,
    FxImpactUnit = EffectTemplate.TNapalmHvyCarpetBombHitLand01,
    FxImpactProp = EffectTemplate.TNapalmHvyCarpetBombHitLand01,
    FxImpactLand = EffectTemplate.TNapalmHvyCarpetBombHitLand01,
    FxImpactWater = EffectTemplate.TNapalmHvyCarpetBombHitLand01,
    FxImpactShield = EffectTemplate.TNapalmHvyCarpetBombHitLand01,
    PolyTrail = '/effects/emitters/default_polytrail_01_emit.bp',
}

---  TERRAN PLASMA CANNON PROJECTILES
---@class TPlasmaCannonProjectile : SinglePolyTrailProjectile
TPlasmaCannonProjectile = ClassProjectile(SinglePolyTrailProjectile) {
    FxTrails = EffectTemplate.TPlasmaCannonLightMunition,
    PolyTrailOffset = 0,
    PolyTrail = EffectTemplate.TPlasmaCannonLightPolyTrail,
    FxImpactUnit = EffectTemplate.TPlasmaCannonLightHitUnit01,
    FxImpactProp = EffectTemplate.TPlasmaCannonLightHitUnit01,
    FxImpactLand = EffectTemplate.TPlasmaCannonLightHitLand01,
}

---  TERRAN RAIL GUN PROJECTILES
---@class TRailGunProjectile : SinglePolyTrailProjectile
TRailGunProjectile = ClassProjectile(SinglePolyTrailProjectile) {
    PolyTrail = '/effects/emitters/railgun_polytrail_01_emit.bp',
    FxTrailScale = 1,
    FxTrailOffset = 0,
    FxImpactUnit = EffectTemplate.TRailGunHitGround01,
    FxImpactProp = EffectTemplate.TRailGunHitGround01,
    FxImpactAirUnit = EffectTemplate.TRailGunHitAir01,
}

---  TERRAN PHALANX PROJECTILES
---@class TShellPhalanxProjectile : MultiPolyTrailProjectile
TShellPhalanxProjectile = ClassProjectile(MultiPolyTrailProjectile) {
    PolyTrails = EffectTemplate.TPhalanxGunPolyTrails,
    PolyTrailOffset = EffectTemplate.TPhalanxGunPolyTrailsOffsets,
    FxImpactUnit = EffectTemplate.TRiotGunHitUnit01,
    FxImpactProp = EffectTemplate.TRiotGunHitUnit01,
    FxImpactNone = EffectTemplate.FireCloudSml01,
    FxImpactLand = EffectTemplate.TRiotGunHit01,
    FxImpactProjectile = EffectTemplate.TMissileHit02,
    FxProjectileHitScale = 0.7,
}

---  TERRAN RIOT PROJECTILES
---@class TShellRiotProjectile : MultiPolyTrailProjectile
TShellRiotProjectile = ClassProjectile(MultiPolyTrailProjectile) {
    PolyTrails = EffectTemplate.TRiotGunPolyTrails,
    PolyTrailOffset = EffectTemplate.TRiotGunPolyTrailsOffsets,
    FxTrails = EffectTemplate.TRiotGunMunition01,
    RandomPolyTrails = 1,
    FxImpactUnit = EffectTemplate.TRiotGunHitUnit01,
    FxImpactProp = EffectTemplate.TRiotGunHitUnit01,
    FxImpactLand = EffectTemplate.TRiotGunHit01,
}

---@class TShellRiotProjectileLand : MultiPolyTrailProjectile
TShellRiotProjectileLand = ClassProjectile(MultiPolyTrailProjectile) {
    PolyTrails = EffectTemplate.TRiotGunPolyTrailsTank,
    PolyTrailOffset = EffectTemplate.TRiotGunPolyTrailsOffsets,
    RandomPolyTrails = 1,
    FxImpactUnit = EffectTemplate.TRiotGunHitUnit02,
    FxImpactProp = EffectTemplate.TRiotGunHitUnit02,
    FxImpactLand = EffectTemplate.TRiotGunHit02,
}

---@class TShellRiotProjectileLand02 : TShellRiotProjectileLand
TShellRiotProjectileLand02 = ClassProjectile(TShellRiotProjectileLand) {
    PolyTrails = EffectTemplate.TRiotGunPolyTrailsEngineer,
}

---  TERRAN ABOVE WATER LAUNCHED TORPEDO
---@class TTorpedoShipProjectile : OnWaterEntryEmitterProjectile
TTorpedoShipProjectile = ClassProjectile(OnWaterEntryEmitterProjectile) {
    FxTrails = { '/effects/emitters/torpedo_underwater_wake_01_emit.bp', },
    TrailDelay = 0,
    FxUnitHitScale = 1.25,
    FxImpactLand = EffectTemplate.TGaussCannonHit01,
    FxImpactUnit = EffectTemplate.TTorpedoHitUnit01,
    FxImpactProp = EffectTemplate.TTorpedoHitUnit01,
    FxImpactUnderWater = EffectTemplate.TTorpedoHitUnitUnderwater01,
    FxEnterWater = EffectTemplate.WaterSplash01,

    ---@param self TTorpedoShipProjectile
    ---@param inWater? boolean
    OnCreate = function(self, inWater)
        OnWaterEntryEmitterProjectile.OnCreate(self)

        -- if we are starting in the water then immediately switch to tracking in water and
        -- create underwater trail effects
        if inWater == true then
            self:SetWaterParameters()
        end
    end,

    ---@param self TTorpedoShipProjectile
    OnEnterWater = function(self)
        OnWaterEntryEmitterProjectile.OnEnterWater(self)
        self:SetWaterParameters()
    end,

    ---@param self TTorpedoShipProjectile
    MovementThread = function(self)
    end,

    ---@param self TTorpedoShipProjectile
    SetWaterParameters = function(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)
        -- self:SetMaxSpeed(20)
        -- self:SetAcceleration(5)
        -- self:SetTurnRate(140)
        -- self:SetVelocity(10)
        self.Trash:Add(ForkThread(self.MovementThread, self))
    end,
}

---  TERRAN SUB LAUNCHED TORPEDO
---@class TTorpedoSubProjectile : EmitterProjectile
TTorpedoSubProjectile = ClassProjectile(EmitterProjectile) {
    FxTrails = { '/effects/emitters/torpedo_munition_trail_01_emit.bp', },
    FxUnitHitScale = 1.25,
    FxImpactUnit = EffectTemplate.TTorpedoHitUnit01,
    FxImpactProp = EffectTemplate.TTorpedoHitUnit01,
    FxImpactUnderWater = EffectTemplate.TTorpedoHitUnit01,

    ---@param self TTorpedoSubProjectile
    ---@param inWater? boolean unused
    OnCreate = function(self, inWater)
        EmitterProjectile.OnCreate(self, inWater)
        self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)
    end,
}

---  SC1X UEF BASE TEMPRORARY PROJECTILE
---@class TBaseTempProjectile : SinglePolyTrailProjectile
TBaseTempProjectile = ClassProjectile(SinglePolyTrailProjectile) {
    FxImpactLand = EffectTemplate.AMissileHit01,
    FxImpactNone = EffectTemplate.AMissileHit01,
    FxImpactProjectile = EffectTemplate.ASaintImpact01,
    FxImpactProp = EffectTemplate.AMissileHit01,
    FxImpactUnit = EffectTemplate.AMissileHit01,
    FxTrails = {
        '/effects/emitters/aeon_laser_fxtrail_01_emit.bp',
        '/effects/emitters/aeon_laser_fxtrail_02_emit.bp',
    },
    PolyTrail = '/effects/emitters/aeon_laser_trail_01_emit.bp',
}

---  UEF PLASMA GATLING CANNON PROJECTILE
---@class TGatlingPlasmaCannonProjectile : MultiPolyTrailProjectile
TGatlingPlasmaCannonProjectile = ClassProjectile(MultiPolyTrailProjectile) {
    PolyTrailOffset = EffectTemplate.TPlasmaGatlingCannonPolyTrailsOffsets,
    FxImpactNone = EffectTemplate.TPlasmaGatlingCannonUnitHit,
    FxImpactUnit = EffectTemplate.TPlasmaGatlingCannonUnitHit,
    FxImpactProp = EffectTemplate.TPlasmaGatlingCannonUnitHit,
    FxImpactLand = EffectTemplate.TPlasmaGatlingCannonHit,
    FxImpactWater = EffectTemplate.TPlasmaGatlingCannonHit,
    RandomPolyTrails = 1,
    PolyTrails = EffectTemplate.TPlasmaGatlingCannonPolyTrails,
}

---  UEF IONIZED PLASMA GATLING CANNON PROJECTILE
--- percival
---@class TIonizedPlasmaGatlingCannon : SinglePolyTrailProjectile
TIonizedPlasmaGatlingCannon = ClassProjectile(SinglePolyTrailProjectile) {
    FxImpactWater = EffectTemplate.TIonizedPlasmaGatlingCannonHit,
    FxImpactLand = EffectTemplate.TIonizedPlasmaGatlingCannonHit,
    FxImpactNone = EffectTemplate.TIonizedPlasmaGatlingCannonHit,
    FxImpactProp = EffectTemplate.TIonizedPlasmaGatlingCannonUnitHit,
    FxImpactUnit = EffectTemplate.TIonizedPlasmaGatlingCannonUnitHit,
    FxTrails = EffectTemplate.TIonizedPlasmaGatlingCannonFxTrails,
    PolyTrail = EffectTemplate.TIonizedPlasmaGatlingCannonPolyTrail,
}

---  UEF HEAVY PLASMA GATLING CANNON PROJECTILE
--- ravager
---@class THeavyPlasmaGatlingCannon : SinglePolyTrailProjectile
THeavyPlasmaGatlingCannon = ClassProjectile(SinglePolyTrailProjectile) {
    FxImpactTrajectoryAligned = false,
    FxImpactUnit = EffectTemplate.THeavyPlasmaGatlingCannonHit,
    FxImpactProp = EffectTemplate.THeavyPlasmaGatlingCannonHit,
    FxImpactWater = EffectTemplate.THeavyPlasmaGatlingCannonHit,
    FxImpactLand = EffectTemplate.THeavyPlasmaGatlingCannonHit,
    FxTrails = EffectTemplate.THeavyPlasmaGatlingCannonFxTrails,
    PolyTrail = EffectTemplate.THeavyPlasmaGatlingCannonPolyTrail,
}

--- this used to be the tri barelled hiro cannon.
---@class THiroLaser : SinglePolyTrailProjectile
THiroLaser = ClassProjectile(SinglePolyTrailProjectile) {
    FxTrailOffset = 0,
    FxImpactUnit = EffectTemplate.THiroLaserUnitHit,
    FxImpactProp = EffectTemplate.THiroLaserHit,
    FxImpactLand = EffectTemplate.THiroLaserLandHit,
    FxImpactWater = EffectTemplate.THiroLaserLandHit,
    FxTrails = EffectTemplate.THiroLaserFxtrails,
    PolyTrail = EffectTemplate.THiroLaserPolytrail,
}

-- kept for mod backwards compatability
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local util = import('utilities.lua')
local Explosion = import('defaultexplosions.lua')
local Projectile = import('/lua/sim/projectile.lua').Projectile

------------------------------------------------------------
--  File     : /lua/terranprojectiles.lua
--  Author(s): John Comes, Gordon Duclos, Matt Vainio
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------
local DefaultProjectileFile = import("/lua/sim/defaultprojectiles.lua")
local EmitterProjectile = import("/lua/sim/defaultprojectiles.lua").EmitterProjectile
local OnWaterEntryEmitterProjectile = import("/lua/sim/defaultprojectiles.lua").OnWaterEntryEmitterProjectile
local SingleBeamProjectile = import("/lua/sim/defaultprojectiles.lua").SingleBeamProjectile
local SinglePolyTrailProjectile = import("/lua/sim/defaultprojectiles.lua").SinglePolyTrailProjectile
local MultiPolyTrailProjectile = import("/lua/sim/defaultprojectiles.lua").MultiPolyTrailProjectile
local SingleCompositeEmitterProjectile = import("/lua/sim/defaultprojectiles.lua").SingleCompositeEmitterProjectile
local EffectTemplate = import("/lua/effecttemplates.lua")
local DepthCharge = import("/lua/defaultantiprojectile.lua").DepthCharge
local NukeProjectile = import("/lua/sim/defaultprojectiles.lua").NukeProjectile

local DebrisComponent = import('/lua/sim/projectiles/components/DebrisComponent.lua').DebrisComponent
local TacticalMissileComponent = import('/lua/sim/defaultprojectiles.lua').TacticalMissileComponent

TFragmentationGrenade = import("/lua/sim/projectiles/uef/TFragmentationGrenadeProjectile.lua").TFragmentationGrenade
TIFMissileNuke = import("/lua/sim/projectiles/uef/TIFMissileNukeProjectile.lua").TIFMissileNuke
TIFTacticalNuke = import("/lua/sim/projectiles/uef/TIFTacticalNukeProjectile.lua").TIFTacticalNuke
TAAGinsuRapidPulseBeamProjectile = import("/lua/sim/projectiles/uef/TAAGinsuRapidPulseBeamProjectile.lua").TAAGinsuRapidPulseBeamProjectile
TAALightFragmentationProjectile = import("/lua/sim/projectiles/uef/TAALightFragmentationProjectile.lua").TAALightFragmentationProjectile
TArtilleryAntiMatterProjectile = import("/lua/sim/projectiles/uef/TArtilleryAntiMatterProjectile.lua").TArtilleryAntiMatterProjectile
TArtilleryAntiMatterProjectile02 = import("/lua/sim/projectiles/uef/TArtilleryAntiMatterProjectile02.lua").TArtilleryAntiMatterProjectile02
TArtilleryAntiMatterSmallProjectile = import("/lua/sim/projectiles/uef/TArtilleryAntiMatterSmallProjectile.lua").TArtilleryAntiMatterSmallProjectile
TArtilleryProjectile = import("/lua/sim/projectiles/uef/TArtilleryProjectile.lua").TArtilleryProjectile
TArtilleryProjectilePolytrail = import("/lua/sim/projectiles/uef/TArtilleryProjectilePolytrail.lua").TArtilleryProjectilePolytrail
TCannonSeaProjectile = import("/lua/sim/projectiles/uef/TCannonSeaProjectile.lua").TCannonSeaProjectile
TCannonTankProjectile = import("/lua/sim/projectiles/uef/TCannonTankProjectile.lua").TCannonTankProjectile
TDepthChargeProjectile = import("/lua/sim/projectiles/uef/TDepthChargeProjectile.lua").TDepthChargeProjectile
TDFGeneralGaussCannonProjectile = import("/lua/sim/projectiles/uef/TDFGeneralGaussCannonProjectile.lua").TDFGeneralGaussCannonProjectile
TDFGaussCannonProjectile = import("/lua/sim/projectiles/uef/TDFGaussCannonProjectile.lua").TDFGaussCannonProjectile
TDFMediumShipGaussCannonProjectile = import("/lua/sim/projectiles/uef/TDFMediumShipGaussCannonProjectile.lua").TDFMediumShipGaussCannonProjectile
TDFBigShipGaussCannonProjectile = import("/lua/sim/projectiles/uef/TDFBigShipGaussCannonProjectile.lua").TDFBigShipGaussCannonProjectile
TDFMediumLandGaussCannonProjectile = import("/lua/sim/projectiles/uef/TDFMediumLandGaussCannonProjectile.lua").TDFMediumLandGaussCannonProjectile
TDFBigLandGaussCannonProjectile = import("/lua/sim/projectiles/uef/TDFBigLandGaussCannonProjectile.lua").TDFBigLandGaussCannonProjectile
THeavyPlasmaCannonProjectile = import("/lua/sim/projectiles/uef/THeavyPlasmaCannonProjectile.lua").THeavyPlasmaCannonProjectile
TIFSmallYieldNuclearBombProjectile = import("/lua/sim/projectiles/uef/TIFSmallYieldNuclearBombProjectile.lua").TIFSmallYieldNuclearBombProjectile
TLaserBotProjectile = import("/lua/sim/projectiles/uef/TLaserBotProjectile.lua").TLaserBotProjectile
TLaserProjectile = import("/lua/sim/projectiles/uef/TLaserProjectile.lua").TLaserProjectile
TMachineGunProjectile = import("/lua/sim/projectiles/uef/TMachineGunProjectile.lua").TMachineGunProjectile
TMissileAAProjectile = import("/lua/sim/projectiles/uef/TMissileAAProjectile.lua").TMissileAAProjectile
TAntiNukeInterceptorProjectile = import("/lua/sim/projectiles/uef/TAntiNukeInterceptorProjectile.lua").TAntiNukeInterceptorProjectile
TMissileProjectile = import("/lua/sim/projectiles/uef/TMissileProjectile.lua").TMissileProjectile
TMissileCruiseProjectile = import("/lua/sim/projectiles/uef/TMissileCruiseProjectile.lua").TMissileCruiseProjectile
TMissileCruiseProjectile02 = import("/lua/sim/projectiles/uef/TMissileCruiseProjectile02.lua").TMissileCruiseProjectile02

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

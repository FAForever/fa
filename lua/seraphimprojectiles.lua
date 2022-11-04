------------------------------------------------------------
--
--  File     :  /cdimage/lua/seraphimprojectiles.lua
--  Author(s):  Gordon Duclos, Greg Kohne, Matt Vainio, Aaron Lundquist
--
--  Summary  : Seraphim projectile base class definitions
--
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------

--------------------------------------------------------------------------
--  SERAPHIM PROJECTILES SCRIPTS
--------------------------------------------------------------------------
local DefaultProjectileFile = import("/lua/sim/defaultprojectiles.lua")
local SinglePolyTrailProjectile = DefaultProjectileFile.SinglePolyTrailProjectile
local MultiPolyTrailProjectile = DefaultProjectileFile.MultiPolyTrailProjectile
local EffectTemplate = import("/lua/effecttemplates.lua")
local EmitterProjectile = DefaultProjectileFile.EmitterProjectile
local util = import("/lua/utilities.lua")
local RandomInt = util.GetRandomInt
local NukeProjectile = DefaultProjectileFile.NukeProjectile

--------------------------------------------------------------------------
--  SERAPHIM ANTI-NUKE PROJECTILES
--------------------------------------------------------------------------
---@class SIFHuAntiNuke : SinglePolyTrailProjectile
SIFHuAntiNuke = Class(SinglePolyTrailProjectile) {
    FxImpactTrajectoryAligned = false,
    PolyTrail = EffectTemplate.SKhuAntiNukePolyTrail,
    FxTrails = EffectTemplate.SKhuAntiNukeFxTrails,
    FxImpactUnit = {},
    FxImpactProp = {},
    FxImpactNone = {},
    FxImpactLand = {},
    FxImpactProjectile = EffectTemplate.SKhuAntiNukeHit,
    FxImpactUnderWater = {},
}

---@class SIFKhuAntiNukeTendril : EmitterProjectile
SIFKhuAntiNukeTendril = Class(EmitterProjectile) {
    FxImpactTrajectoryAligned = false,
    -- PolyTrail = EffectTemplate.SKhuAntiNukePolyTrail,
    FxTrails = EffectTemplate.SKhuAntiNukeHitTendrilFxTrails,
    FxImpactUnit = {},
    FxImpactProp = {},
    FxImpactNone = {},
    FxImpactLand = {},
    FxImpactProjectile = {},
    FxImpactUnderWater = {},
}

---@class SIFKhuAntiNukeSmallTendril : EmitterProjectile
SIFKhuAntiNukeSmallTendril = Class(EmitterProjectile) {
    FxImpactTrajectoryAligned = false,
    FxTrails = EffectTemplate.SKhuAntiNukeHitSmallTendrilFxTrails,
    FxImpactUnit = {},
    FxImpactProp = {},
    FxImpactNone = {},
    FxImpactLand = {},
    FxImpactProjectile = {},
    FxImpactUnderWater = {},
}

--------------------------------------------------------------------------
--  TEMPORARY BASE SERAPHIM PROJECTILE
--------------------------------------------------------------------------
---@class SBaseTempProjectile : EmitterProjectile
SBaseTempProjectile = Class(EmitterProjectile) {
    FxImpactLand = EffectTemplate.AMissileHit01,
    FxImpactNone = EffectTemplate.AMissileHit01,
    FxImpactProjectile = EffectTemplate.ASaintImpact01,
    FxImpactProp = EffectTemplate.AMissileHit01,
    FxImpactUnderWater = {},
    FxImpactUnit = EffectTemplate.AMissileHit01,
    FxTrails = EffectTemplate.SShleoCannonProjectileTrails,
}

--------------------------------------------------------------------------
--  SERAPHIM CHRONATRON CANNONS
--------------------------------------------------------------------------
---@class SChronatronCannon : MultiPolyTrailProjectile
SChronatronCannon = Class(MultiPolyTrailProjectile) { 
    -- ACU
    FxImpactTrajectoryAligned = false,
    FxImpactLand = EffectTemplate.SChronotronCannonLandHit,
    FxImpactNone = EffectTemplate.SChronotronCannonHit,
    FxImpactProp = EffectTemplate.SChronotronCannonLandHit,
    FxImpactUnit = EffectTemplate.SChronotronCannonUnitHit,
    FxImpactWater = EffectTemplate.SChronotronCannonLandHit,
    FxImpactUnderWater = EffectTemplate.SChronotronCannonHit,
    FxTrails = EffectTemplate.SChronotronCannonProjectileFxTrails,
    PolyTrails = EffectTemplate.SChronotronCannonProjectileTrails,
    PolyTrailOffset = {0,0,0},
}

---@class SChronatronCannonOverCharge : MultiPolyTrailProjectile
SChronatronCannonOverCharge = Class(MultiPolyTrailProjectile) { 
    -- ACU
    FxImpactTrajectoryAligned = false,
    FxImpactLand = EffectTemplate.SChronotronCannonOverChargeLandHit,
    FxImpactNone = EffectTemplate.SChronotronCannonOverChargeLandHit,
    FxImpactProp = EffectTemplate.SChronotronCannonOverChargeLandHit,
    FxImpactUnit = EffectTemplate.SChronotronCannonOverChargeUnitHit,
    FxTrails = EffectTemplate.SChronotronCannonOverChargeProjectileFxTrails,
    PolyTrails = EffectTemplate.SChronotronCannonOverChargeProjectileTrails,
    PolyTrailOffset = {0,0,0},
}

---@class SLightChronatronCannon : MultiPolyTrailProjectile
SLightChronatronCannon = Class(MultiPolyTrailProjectile) { 
    -- SACU
    FxImpactTrajectoryAligned = false,
    FxImpactLand = EffectTemplate.SLightChronotronCannonLandHit,
    FxImpactNone = EffectTemplate.SLightChronotronCannonLandHit,
    FxImpactProp = EffectTemplate.SLightChronotronCannonHit,
    FxImpactUnit = EffectTemplate.SLightChronotronCannonUnitHit,
    PolyTrails = EffectTemplate.SLightChronotronCannonProjectileTrails,
    PolyTrailOffset = {0,0,0},
    FxTrails = EffectTemplate.SLightChronotronCannonProjectileFxTrails,
    FxImpactWater = EffectTemplate.SLightChronotronCannonLandHit,
    FxImpactUnderWater = EffectTemplate.SLightChronotronCannonHit,
}

---@class SLightChronatronCannonOverCharge : MultiPolyTrailProjectile
SLightChronatronCannonOverCharge = Class(MultiPolyTrailProjectile) { 
    -- SACU
    FxImpactTrajectoryAligned = false,
    FxImpactLand = EffectTemplate.SLightChronotronCannonOverChargeHit,
    FxImpactNone = EffectTemplate.SLightChronotronCannonOverChargeHit,
    FxImpactProp = EffectTemplate.SLightChronotronCannonOverChargeHit,
    FxImpactUnit = EffectTemplate.SLightChronotronCannonOverChargeHit,
    PolyTrails = EffectTemplate.SLightChronotronCannonOverChargeProjectileTrails,
    FxTrails = EffectTemplate.SLightChronotronCannonOverChargeProjectileFxTrails,
    PolyTrailOffset = {0,0,0},
}

--------------------------------------------------------------------------
--  SERAPHIM PHASIC AUTOGUNS
--------------------------------------------------------------------------
---@class SPhasicAutogun : MultiPolyTrailProjectile
SPhasicAutogun = Class(MultiPolyTrailProjectile) {
    FxImpactLand = EffectTemplate.PhasicAutoGunHit,
    FxImpactNone = EffectTemplate.PhasicAutoGunHit,
    FxImpactProp = EffectTemplate.PhasicAutoGunHitUnit,
    FxImpactUnit = EffectTemplate.PhasicAutoGunHitUnit,
    PolyTrails = EffectTemplate.PhasicAutoGunProjectileTrail,
    PolyTrailOffset = {0,0},
}

---@class SHeavyPhasicAutogun : MultiPolyTrailProjectile
SHeavyPhasicAutogun = Class(MultiPolyTrailProjectile) { 
    -- T2 gunship and T2 transport
    FxImpactLand = EffectTemplate.HeavyPhasicAutoGunHit,
    FxImpactNone = EffectTemplate.HeavyPhasicAutoGunHit,
    FxImpactProp = EffectTemplate.HeavyPhasicAutoGunHitUnit,
    FxImpactUnit = EffectTemplate.HeavyPhasicAutoGunHitUnit,
    FxImpactWater = EffectTemplate.HeavyPhasicAutoGunHit,
    FxImpactUnderWater = EffectTemplate.HeavyPhasicAutoGunHitUnit,
    PolyTrails = EffectTemplate.HeavyPhasicAutoGunProjectileTrail,
    FxTrails = EffectTemplate.HeavyPhasicAutoGunProjectileTrailGlow,
    PolyTrailOffset = {0,0},
}

-- Adjustment for XSA0203 projectile speed. : T2 gunship
---@class SHeavyPhasicAutogun02 : SHeavyPhasicAutogun
SHeavyPhasicAutogun02 = Class(SHeavyPhasicAutogun) {
    PolyTrails = EffectTemplate.HeavyPhasicAutoGunProjectileTrail02,
    FxTrails = EffectTemplate.HeavyPhasicAutoGunProjectileTrailGlow02,
}

--------------------------------------------------------------------------
--  SERAPHIM OH CANNONS
--------------------------------------------------------------------------
---@class SOhCannon : MultiPolyTrailProjectile
SOhCannon = Class(MultiPolyTrailProjectile) {
    FxImpactLand = EffectTemplate.OhCannonHit,
    FxImpactNone = EffectTemplate.OhCannonHit,
    FxImpactProp = EffectTemplate.OhCannonHitUnit,
    FxImpactUnit = EffectTemplate.OhCannonHitUnit,
    FxTrails = {},
    PolyTrails = EffectTemplate.OhCannonProjectileTrail,
    PolyTrailOffset = {0,0},
}

---@class SOhCannon02 : MultiPolyTrailProjectile
SOhCannon02 = Class(MultiPolyTrailProjectile) {
    FxImpactLand = EffectTemplate.OhCannonHit,
    FxImpactNone = EffectTemplate.OhCannonHit,
    FxImpactProp = EffectTemplate.OhCannonHitUnit,
    FxImpactUnit = EffectTemplate.OhCannonHitUnit,
    FxTrails = {},
    PolyTrails = EffectTemplate.OhCannonProjectileTrail02,
    PolyTrailOffset = {0,0,0},
}

--------------------------------------------------------------------------
--  SERAPHIM SHRIEKER AUTO-CANNONS
--------------------------------------------------------------------------
---@class SShriekerAutoCannon : MultiPolyTrailProjectile
SShriekerAutoCannon = Class(MultiPolyTrailProjectile) {

    FxImpactLand = EffectTemplate.ShriekerCannonHit,
    FxImpactNone = EffectTemplate.ShriekerCannonHit,
    FxImpactProp = EffectTemplate.ShriekerCannonHit,
    FxImpactUnit = EffectTemplate.ShriekerCannonHitUnit,
    PolyTrails = EffectTemplate.ShriekerCannonPolyTrail,
    FxImpactWater = EffectTemplate.ShriekerCannonHit,
    FxImpactUnderWater = EffectTemplate.ShriekerCannonHit,
    PolyTrailOffset = {0,0,0},
}

--------------------------------------------------------------------------
--  SERAPHIM AIRE-AU BOLTER
--------------------------------------------------------------------------
---@class SAireauBolter : MultiPolyTrailProjectile
SAireauBolter = Class(MultiPolyTrailProjectile) { 
    -- T2 bot (Ilshavoh) and T3 tank (Othuum)
    FxImpactLand = EffectTemplate.SAireauBolterHit,
    FxImpactNone = EffectTemplate.SAireauBolterHit,
    FxImpactProp = EffectTemplate.SAireauBolterHit,
    FxImpactUnit = EffectTemplate.SAireauBolterHit,
    FxTrails = EffectTemplate.SAireauBolterProjectileFxTrails,
    PolyTrailOffset = {0,0,0},
    PolyTrails = EffectTemplate.SAireauBolterProjectilePolyTrails,
}

--------------------------------------------------------------------------
--  SERAPHIM TAU CANNON
--------------------------------------------------------------------------
---@class STauCannon : MultiPolyTrailProjectile
STauCannon = Class(MultiPolyTrailProjectile) { 
    -- sera T2 hover tank and T3 tank (othuum)
    FxImpactLand = EffectTemplate.STauCannonHit,
    FxImpactNone = EffectTemplate.STauCannonHit,
    FxImpactProp = EffectTemplate.STauCannonHit,
    FxImpactUnit = EffectTemplate.STauCannonHit,
    FxTrails = EffectTemplate.STauCannonProjectileTrails,
    PolyTrailOffset = {0,0},
    PolyTrails = EffectTemplate.STauCannonProjectilePolyTrails,
}

------------------------------------------------------------------------
--  SERAPHIM HEAVY QUARNON CANNON
--------------------------------------------------------------------------
---@class SHeavyQuarnonCannon : MultiPolyTrailProjectile
SHeavyQuarnonCannon = Class(MultiPolyTrailProjectile) { 
    -- Battleship
    FxImpactLand = EffectTemplate.SHeavyQuarnonCannonLandHit,
    FxImpactNone = EffectTemplate.SHeavyQuarnonCannonHit,
    FxImpactProp = EffectTemplate.SHeavyQuarnonCannonHit,
    FxImpactUnit = EffectTemplate.SHeavyQuarnonCannonUnitHit,
    PolyTrails = EffectTemplate.SHeavyQuarnonCannonProjectilePolyTrails,
    PolyTrailOffset = {0,0,0},
    FxTrails = EffectTemplate.SHeavyQuarnonCannonProjectileFxTrails,
    FxImpactWater = EffectTemplate.SHeavyQuarnonCannonWaterHit,
}

------------------------------------------------------------------------
--  SERAPHIM LAANSE TACTICAL MISSILE
--------------------------------------------------------------------------
---@class SLaanseTacticalMissile : SinglePolyTrailProjectile
SLaanseTacticalMissile = Class(SinglePolyTrailProjectile) { 
    -- ACU / SACU / TML /MML
    FxImpactLand = EffectTemplate.SLaanseMissleHit,
    FxImpactProp = EffectTemplate.SLaanseMissleHitUnit,
    FxImpactUnderWater = {},
    FxImpactUnit = EffectTemplate.SLaanseMissleHitUnit,
    FxTrails = EffectTemplate.SLaanseMissleExhaust02,
    PolyTrail = EffectTemplate.SLaanseMissleExhaust01,

    ---@param self SLaanseMissileWeapon
    OnCreate = function(self)
        SinglePolyTrailProjectile.OnCreate(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)
    end,
}

--------------------------------------------------------------------------
--  SERAPHIM ZTHUTHAAM ARTILLERY SHELL
--------------------------------------------------------------------------
---@class SZthuthaamArtilleryShell : MultiPolyTrailProjectile
SZthuthaamArtilleryShell = Class(MultiPolyTrailProjectile) {
    FxImpactLand = EffectTemplate.SZthuthaamArtilleryHit,
    FxImpactWater = EffectTemplate.SZthuthaamArtilleryHit,
    FxImpactNone = EffectTemplate.SZthuthaamArtilleryHit,
    FxImpactProjectile = {},
    FxImpactProp = EffectTemplate.SZthuthaamArtilleryHit,
    FxImpactUnderWater = {},
    FxImpactUnit = EffectTemplate.SZthuthaamArtilleryUnitHit,
    FxTrails = EffectTemplate.SZthuthaamArtilleryProjectileFXTrails,
    PolyTrails = EffectTemplate.SZthuthaamArtilleryProjectilePolyTrails,
    PolyTrailOffset = {0,0},
}

--------------------------------------------------------------------------
--  SERAPHIM SUTHANUS ARTILLERY SHELL
--------------------------------------------------------------------------
---@class SSuthanusArtilleryShell : EmitterProjectile
SSuthanusArtilleryShell = Class(EmitterProjectile) {
    FxImpactTrajectoryAligned = false,
    FxImpactLand = EffectTemplate.SRifterArtilleryHit,
    FxImpactWater = EffectTemplate.SRifterArtilleryWaterHit,
    FxImpactNone = EffectTemplate.SRifterArtilleryHit,
    FxImpactProjectile = {},
    FxImpactProp = EffectTemplate.SRifterArtilleryHit,
    FxImpactUnderWater = EffectTemplate.SRifterArtilleryWaterHit,
    FxImpactUnit = EffectTemplate.SRifterArtilleryHit,
    FxTrails = EffectTemplate.SRifterArtilleryProjectileFxTrails,
    PolyTrail = EffectTemplate.SRifterArtilleryProjectilePolyTrail,
}

--------------------------------------------------------------------------
--  SERAPHIM MOBILE SUTHANUS ARTILLERY SHELL
--------------------------------------------------------------------------
---@class SSuthanusMobileArtilleryShell : SinglePolyTrailProjectile
SSuthanusMobileArtilleryShell = Class(SinglePolyTrailProjectile) {
    -- This will make ist so that the projectile effects are the in the space of the world
    FxImpactTrajectoryAligned = false,
    FxImpactLand = EffectTemplate.SRifterMobileArtilleryHit,
    FxImpactWater = EffectTemplate.SRifterMobileArtilleryWaterHit,
    FxImpactNone = EffectTemplate.SRifterMobileArtilleryHit,
    FxImpactProjectile = {},
    FxImpactProp = EffectTemplate.SRifterMobileArtilleryHit,
    FxImpactUnderWater = EffectTemplate.SRifterMobileArtilleryWaterHit,
    FxImpactUnit = EffectTemplate.SRifterMobileArtilleryHit,
    FxTrails = EffectTemplate.SRifterMobileArtilleryProjectileFxTrails,
    PolyTrail = EffectTemplate.SRifterArtilleryProjectilePolyTrail,
}

--------------------------------------------------------------------------
--  SERAPHIM THUNTHO ARTILLERY SHELL
--------------------------------------------------------------------------
---@class SThunthoArtilleryShell : MultiPolyTrailProjectile
SThunthoArtilleryShell = Class(MultiPolyTrailProjectile) {
    FxImpactTrajectoryAligned = false,
    FxImpactLand = EffectTemplate.SThunderStormCannonHit,
    FxImpactNone = EffectTemplate.SThunderStormCannonHit,
    FxImpactProjectile = {},
    FxImpactProp = EffectTemplate.SThunderStormCannonHit,
    FxImpactUnderWater = {},
    FxImpactUnit = EffectTemplate.SThunderStormCannonHit,
    FxTrails = EffectTemplate.SThunderStormCannonProjectileTrails,
    PolyTrails = EffectTemplate.SThunderStormCannonProjectilePolyTrails,
    PolyTrailOffset = {0,0},
}

---@class SThunthoArtilleryShell2 : MultiPolyTrailProjectile
SThunthoArtilleryShell2 = Class(MultiPolyTrailProjectile) {
    FxImpactTrajectoryAligned = false,
    FxImpactLand = EffectTemplate.SThunderStormCannonLandHit,
    FxImpactWater= EffectTemplate.SThunderStormCannonLandHit,
    FxImpactNone = EffectTemplate.SThunderStormCannonHit,
    FxImpactProjectile = {},
    FxImpactProp = EffectTemplate.SThunderStormCannonHit,
    FxImpactUnderWater = {},
    FxImpactUnit = EffectTemplate.SThunderStormCannonUnitHit,
    FxTrails = {},
    PolyTrails = EffectTemplate.SThunderStormCannonProjectilePolyTrails,
    PolyTrailOffset = {0,0},
}

--------------------------------------------------------------------------
--  SERAPHIM SHLEO AA GATLING ROUND
--------------------------------------------------------------------------
---@class SShleoAACannon : EmitterProjectile
SShleoAACannon = Class(EmitterProjectile) {
    FxImpactAirUnit = EffectTemplate.SShleoCannonUnitHit,
    FxImpactLand = EffectTemplate.SShleoCannonLandHit,
    FxImpactWater = EffectTemplate.SShleoCannonLandHit,
    FxImpactNone = EffectTemplate.SShleoCannonHit,
    FxImpactProjectile = {},
    FxImpactProp = EffectTemplate.SShleoCannonHit,
    FxImpactUnderWater = {},
    FxImpactUnit = EffectTemplate.SShleoCannonUnitHit,
    FxTrails = {},
    PolyTrails = EffectTemplate.SShleoCannonProjectilePolyTrails,

    ---@param self SShleoAACannon
    OnCreate = function(self)
        EmitterProjectile.OnCreate(self)
        local PolytrailGroup = self.PolyTrails[RandomInt(1,table.getn(self.PolyTrails))]

        for k, v in PolytrailGroup do
            CreateTrail(self, -1, self.Army, v)
        end
    end,
}

--------------------------------------------------------------------------
--  SERAPHIM OLARIS AA ARTILLERY
--------------------------------------------------------------------------
---@class SOlarisAAArtillery : MultiPolyTrailProjectile
SOlarisAAArtillery = Class(MultiPolyTrailProjectile) {
    FxImpactAirUnit = EffectTemplate.SOlarisCannonHit,
    FxImpactLand = EffectTemplate.SOlarisCannonHit,
    FxImpactNone = EffectTemplate.SOlarisCannonHit,
    FxImpactProp = EffectTemplate.SOlarisCannonHit,
    FxImpactUnit = EffectTemplate.SOlarisCannonHit,
    FxTrails = EffectTemplate.SOlarisCannonTrails,
    PolyTrails = EffectTemplate.SOlarisCannonProjectilePolyTrail,
    PolyTrailOffset = {0,0}
}

--------------------------------------------------------------------------
--  SERAPHIM LOSAARE AA CANNON
--------------------------------------------------------------------------
---@class SLosaareAAAutoCannon : MultiPolyTrailProjectile
SLosaareAAAutoCannon = Class(MultiPolyTrailProjectile) {

    FxImpactLand = EffectTemplate.SLosaareAutoCannonHit,
    FxImpactNone= EffectTemplate.SLosaareAutoCannonHit,
    FxImpactProp = EffectTemplate.SLosaareAutoCannonHit,
    FxImpactAirUnit = EffectTemplate.SLosaareAutoCannonHit,
    PolyTrails = EffectTemplate.SLosaareAutoCannonProjectileTrail,
    PolyTrailOffset = {0,0},
}

--------------------------------------------------------------------------
--  SERAPHIM LOSAARE AA CANNON (XSS0303 / XSS0304 ADJUSTMENTS)
--------------------------------------------------------------------------
---@class SLosaareAAAutoCannon02 : SLosaareAAAutoCannon
SLosaareAAAutoCannon02 = Class(SLosaareAAAutoCannon) {

    PolyTrails = EffectTemplate.SLosaareAutoCannonProjectileTrail02,
    PolyTrailOffset = {0,0},
}


--------------------------------------------------------------------------
--  SERAPHIM OTHE TACTICAL BOMB
--------------------------------------------------------------------------
SOtheTacticalBomb= Class(SinglePolyTrailProjectile) {
    FxImpactLand =			EffectTemplate.SOtheBombHit,
    FxImpactNone =			EffectTemplate.SOtheBombHit,
    FxImpactProjectile =	{},
    FxImpactProp =			EffectTemplate.SOtheBombHitUnit,
    FxImpactUnderWater =	EffectTemplate.SOtheBombHit,
    FxImpactUnit =			EffectTemplate.SOtheBombHitUnit,
    FxTrails =				EffectTemplate.SOtheBombFxTrails,
    PolyTrail =				EffectTemplate.SOtheBombPolyTrail,
}

--------------------------------------------------------------------------
--  SERAPHIM ANA-IT TORPEDO
--------------------------------------------------------------------------
---@class SAnaitTorpedo : MultiPolyTrailProjectile
SAnaitTorpedo = Class(MultiPolyTrailProjectile) {
    FxImpactUnderWater =	EffectTemplate.SAnaitTorpedoHit,
    FxUnderWaterHitScale =	1,
    FxImpactUnit =			EffectTemplate.SAnaitTorpedoHit,
    FxImpactNone =			EffectTemplate.SAnaitTorpedoHit,
    FxTrails =				EffectTemplate.SAnaitTorpedoFxTrails,
    PolyTrails =			EffectTemplate.SAnaitTorpedoPolyTrails,
    PolyTrailOffset =		{0,0},

    ---@param self SAnaitTorpedo
    ---@param inWater boolean
    OnCreate = function(self, inWater)
        self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)
        MultiPolyTrailProjectile.OnCreate(self, inWater)
    end,
}

--------------------------------------------------------------------------
--  SERAPHIM HEAVY CAVITATION TORPEDO
--------------------------------------------------------------------------
---@class SHeavyCavitationTorpedo : MultiPolyTrailProjectile
SHeavyCavitationTorpedo = Class(MultiPolyTrailProjectile) {
    FxImpactLand =			EffectTemplate.SHeavyCavitationTorpedoHit,
    FxImpactNone =			EffectTemplate.SHeavyCavitationTorpedoHit,
    FxImpactProjectile =	{},
    FxImpactProp =			EffectTemplate.SHeavyCavitationTorpedoHit,
    FxImpactUnderWater =	EffectTemplate.SHeavyCavitationTorpedoHit,
    FxImpactUnit =			EffectTemplate.SHeavyCavitationTorpedoHit,
    FxTrails =				{},
    PolyTrails =			EffectTemplate.SHeavyCavitationTorpedoPolyTrails,
    PolyTrailOffset =		{0,0},

    ---@param self SAnaitTorpedo
    ---@param inWater boolean
    OnCreate = function(self, inWater)
        self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)
        MultiPolyTrailProjectile.OnCreate(self, inWater)
    end,
}

--------------------------------------------------------------------------
--  SERAPHIM UALL CAVITATION TORPEDO (SUB LAUNCHED TORPEDO)
--------------------------------------------------------------------------
---@class SUallCavitationTorpedo : SinglePolyTrailProjectile
SUallCavitationTorpedo = Class(SinglePolyTrailProjectile) {
    -- FxImpactLand =			EffectTemplate.SUallTorpedoHit,
    -- FxImpactNone =			EffectTemplate.SUallTorpedoHit,
    -- FxImpactProp =			EffectTemplate.SUallTorpedoHit,
    FxImpactUnderWater =	EffectTemplate.SUallTorpedoHit,
    
    -- Fixed scale from 0.25 to 1.0
    FxUnderWaterHitScale =	1,

    FxTrails =				EffectTemplate.SUallTorpedoFxTrails,
    PolyTrail =				EffectTemplate.SUallTorpedoPolyTrail,

    ---@param self SAnaitTorpedo
    ---@param inWater boolean
    OnCreate = function(self, inWater)
        self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)
        SinglePolyTrailProjectile.OnCreate(self, inWater)
    end,
}


--------------------------------------------------------------------------
--  SERAPHIM Inaino STRATEGIC MISSILE
--------------------------------------------------------------------------
SIFInainoStrategicMissile = Class(NukeProjectile, EmitterProjectile) {
    -- BeamName = '/effects/emitters/missile_exhaust_fire_beam_01_emit.bp',
    ExitWaterTicks = 9,
    FxExitWaterEmitter = EffectTemplate.DefaultProjectileWaterImpact,
    FxInitialAtEntityEmitter = {},
    FxImpactUnit = {},
    FxImpactLand = {},
    FxImpactUnderWater = {},
    FxLaunchTrails = {},
    FxOnEntityEmitter = {},
    FxSplashScale = 0.65,
    FxTrailOffset = -0.5,
    FxTrails = {'/effects/emitters/missile_cruise_munition_trail_01_emit.bp',},
    FxUnderWaterTrail = {'/effects/emitters/missile_cruise_munition_underwater_trail_01_emit.bp',},
}

--------------------------------------------------------------------------
--  SERAPHIM EXPERIMENTAL STRATEGIC MISSILE
--------------------------------------------------------------------------
SExperimentalStrategicMissile = Class(NukeProjectile, MultiPolyTrailProjectile) {
    -- BeamName = '/effects/emitters/missile_exhaust_fire_beam_01_emit.bp',
    ExitWaterTicks = 9,
    FxExitWaterEmitter = EffectTemplate.DefaultProjectileWaterImpact,
    FxInitialAtEntityEmitter = {},
    FxImpactUnit = {},
    FxImpactLand = {},
    FxImpactUnderWater = {},
    FxLaunchTrails = {},
    FxOnEntityEmitter = {},
    FxSplashScale = 0.65,
    FxTrails = EffectTemplate.SIFExperimentalStrategicMissileFXTrails,
    PolyTrails = EffectTemplate.SIFExperimentalStrategicMissilePolyTrails,
    PolyTrailOffset = {0,0,0},
    FxUnderWaterTrail = {'/effects/emitters/missile_cruise_munition_underwater_trail_01_emit.bp',},
}

--------------------------------------------------------------------------
--  SERAPHIM ELECTRUM TACTICAL MISSILE DEFENSE
--------------------------------------------------------------------------
---@class SIMAntiMissile01 : MultiPolyTrailProjectile
SIMAntiMissile01 = Class(MultiPolyTrailProjectile) {
    FxImpactLand = EffectTemplate.SElectrumMissleDefenseHit,
    FxImpactNone= EffectTemplate.SElectrumMissleDefenseHit,
    FxImpactProjectile = EffectTemplate.SElectrumMissleDefenseHit,
    FxImpactProp = EffectTemplate.SElectrumMissleDefenseHit,
    FxImpactUnit = EffectTemplate.SElectrumMissleDefenseHit,
    PolyTrails = EffectTemplate.SElectrumMissleDefenseProjectilePolyTrail,
    PolyTrailOffset = {0,0},
}

--------------------------------------------------------------------------
--  INAINO EXPERIMENTAL STRATEGIC BOMB
--------------------------------------------------------------------------
---@class SExperimentalStrategicBomb : SBaseTempProjectile
SExperimentalStrategicBomb = Class(SBaseTempProjectile) {
    FxImpactTrajectoryAligned = false,
}

---@class SIFNukeWaveTendril : EmitterProjectile
SIFNukeWaveTendril = Class(EmitterProjectile) {
    FxImpactTrajectoryAligned = false,
    -- FxTrails = EffectTemplate.SInfernoHitWaveTendril,  -- TODO: Assign something to this one that is usable.
    FxImpactUnit = {},
    FxImpactProp = {},
    FxImpactNone = {},
    FxImpactLand = {},
    FxImpactProjectile = {},
    FxImpactUnderWater = {},
}

---@class SIFNukeSpiralTendril : EmitterProjectile
SIFNukeSpiralTendril = Class(EmitterProjectile) {
    FxImpactTrajectoryAligned = false,
    -- FxTrails = EffectTemplate.SInfernoHitSpiralTendril,  -- TODO: Assign something to this one that is usable.
    FxImpactUnit = {},
    FxImpactProp = {},
    FxImpactNone = {},
    FxImpactLand = {},
    FxImpactProjectile = {},
    FxImpactUnderWater = {},
}

--------------------------------------------------------------------------
--  ENERGY BEING 'LASER' PROJECTILE WEAPON
--------------------------------------------------------------------------
---@class SEnergyLaser : SBaseTempProjectile
SEnergyLaser = Class(SBaseTempProjectile) {
}

--------------------------------------------------------------------------
--  T3 BOMBER BOMB WEAPON
--------------------------------------------------------------------------
---@class SZhanaseeBombProjectile : EmitterProjectile
SZhanaseeBombProjectile = Class(EmitterProjectile) {
    FxImpactTrajectoryAligned = false,
    FxTrails = EffectTemplate.SZhanaseeBombFxTrails01,
    FxImpactUnit = EffectTemplate.SZhanaseeBombHit01,
    FxImpactProp = EffectTemplate.SZhanaseeBombHit01,
    FxImpactAirUnit = EffectTemplate.SZhanaseeBombHit01,
    FxImpactLand = EffectTemplate.SZhanaseeBombHit01,
    FxImpactUnderWater = {},
}

--------------------------------------------------------------------------
--  HOTHE DECOY FLARE PROJECTILE
--------------------------------------------------------------------------
---@class SAAHotheFlareProjectile : EmitterProjectile
SAAHotheFlareProjectile = Class(EmitterProjectile) {
    FxTrails = EffectTemplate.AAntiMissileFlare,
    FxImpactUnit = {},
    FxImpactAirUnit = {},
    FxImpactNone = EffectTemplate.AAntiMissileFlareHit,
    FxImpactProjectile = EffectTemplate.AAntiMissileFlareHit,
    FxOnKilled = EffectTemplate.AAntiMissileFlareHit,
    FxUnitHitScale = 0.4,
    FxLandHitScale = 0.4,
    FxWaterHitScale = 0.4,
    FxUnderWaterHitScale = 0.4,
    FxAirUnitHitScale = 0.4,
    FxNoneHitScale = 0.4,
    FxImpactLand = {},
    FxImpactUnderWater = {},
    DestroyOnImpact = false,

    --- We only destroy when we hit the ground/water.
    ---@param self SAAHotheFlareProjectile
    ---@param TargetType ImpactType
    ---@param targetEntity Unit | Prop
    OnImpact = function(self, TargetType, targetEntity)
        if type == 'Terrain' or type == 'Water' then
            EmitterProjectile.OnImpact(self, TargetType, targetEntity)
            if TargetType == 'Terrain' or TargetType == 'Water' or TargetType == 'Prop' then
                if self.Trash then
                    self.Trash:Destroy()
                end
                self:Destroy()
            end
        end
    end,
 }

--------------------------------------------------------------------------
--  SERAPHIM OHWALLI STRATEGIC BOMB PROJECTILE
--------------------------------------------------------------------------
---@class SOhwalliStrategicBombProjectile : MultiPolyTrailProjectile
SOhwalliStrategicBombProjectile = Class(MultiPolyTrailProjectile) {
    FxTrails = EffectTemplate.SOhwalliBombFxTrails01,
    PolyTrails = EffectTemplate.SOhwalliBombPolyTrails,
    FxImpactUnit = {},
    FxImpactProp = {},
    FxImpactAirUnit = {},
    FxImpactLand = {},
    FxImpactUnderWater = {},
    PolyTrailOffset = {0,0},
}

--------------------------------------------------------------------------
--  ANJELLU TORPEDO DEFENSE PROJECTILE
--------------------------------------------------------------------------
---@class SAnjelluTorpedoDefenseProjectile : MultiPolyTrailProjectile
SAnjelluTorpedoDefenseProjectile = Class(MultiPolyTrailProjectile) {
    FxImpactProjectileUnderWater = EffectTemplate.SDFAjelluAntiTorpedoHit01,
    PolyTrails = EffectTemplate.SDFAjelluAntiTorpedoPolyTrail01,
    PolyTrailOffset = {0,0},
}

--------------------------------------------------------------------------
--  SERAPHIM SNIPER ENERGY RIFLE
--------------------------------------------------------------------------
---@class SDFSniperShotNormal : MultiPolyTrailProjectile
SDFSniperShotNormal = Class(MultiPolyTrailProjectile) {
    FxImpactLand = EffectTemplate.SDFSniperShotNormalHit,
    FxImpactNone = EffectTemplate.SDFSniperShotNormalHit,
    FxImpactProjectile = {},
    FxImpactProp = EffectTemplate.SDFSniperShotNormalHitUnit,
    FxImpactUnderWater = {},
    FxImpactUnit = EffectTemplate.SDFSniperShotNormalHitUnit,
    FxTrails = {},
    PolyTrails = EffectTemplate.SDFSniperShotNormalPolytrail,
    PolyTrailOffset = {0,0},
}

---@class SDFSniperShot : MultiPolyTrailProjectile
SDFSniperShot = Class(MultiPolyTrailProjectile) {
    FxImpactLand = EffectTemplate.SDFSniperShotHit,
    FxImpactNone = EffectTemplate.SDFSniperShotHit,
    FxImpactProjectile = {},
    FxImpactProp = EffectTemplate.SDFSniperShotHitUnit,
    FxImpactUnderWater = {},
    FxImpactUnit = EffectTemplate.SDFSniperShotHitUnit,
    FxTrails = EffectTemplate.SDFSniperShotTrails,
    PolyTrails = EffectTemplate.SDFSniperShotPolytrail,
    PolyTrailOffset = {0,0},
}

--------------------------------------------------------------------------
--  SERAPHIM EXPERIMENTAL PHASON BEAM PROJECTILE
--------------------------------------------------------------------------

---@class SDFExperimentalPhasonProjectile : EmitterProjectile
SDFExperimentalPhasonProjectile = Class(EmitterProjectile) { 
    -- ythotha
    FxImpactTrajectoryAligned = false,
    FxTrails = EffectTemplate.SDFExperimentalPhasonProjFXTrails01,
    FxImpactUnit = EffectTemplate.SDFExperimentalPhasonProjHitUnit,
    FxImpactProp = EffectTemplate.SDFExperimentalPhasonProjHit01,
    FxImpactLand = EffectTemplate.SDFExperimentalPhasonProjHit01,
    FxImpactWater = EffectTemplate.SDFExperimentalPhasonProjHit01,
}

---@class SDFSinnuntheWeaponProjectile : EmitterProjectile
SDFSinnuntheWeaponProjectile = Class(EmitterProjectile) { 
    -- ythotha
    FxTrails = EffectTemplate.SDFSinnutheWeaponFXTrails01,
    FxImpactUnit = EffectTemplate.SDFSinnutheWeaponHitUnit,
    FxImpactProp = EffectTemplate.SDFSinnutheWeaponHit,
    FxImpactLand = EffectTemplate.SDFSinnutheWeaponHit,
    FxImpactWater = EffectTemplate.SDFSinnutheWeaponHit,
}

---@class SDFAireauProjectile : MultiPolyTrailProjectile
SDFAireauProjectile = Class(MultiPolyTrailProjectile) { 
    -- ythotha
    FxImpactNone = EffectTemplate.SDFAireauWeaponHit01,
    FxImpactUnit = EffectTemplate.SDFAireauWeaponHitUnit,
    FxImpactProp = EffectTemplate.SDFAireauWeaponHit01,
    FxImpactLand = EffectTemplate.SDFAireauWeaponHit01,
    FxImpactWater= EffectTemplate.SDFAireauWeaponHit01,
    RandomPolyTrails = 1,

    PolyTrails = EffectTemplate.SDFAireauWeaponPolytrails01,
    PolyTrailOffset = {0,0,0},
}


-- kept for mod backwards compatibility

local SingleBeamProjectile = DefaultProjectileFile.SingleBeamProjectile
local RandomFloat = import("/lua/utilities.lua").GetRandomFloat
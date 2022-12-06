------------------------------------------------------------
--  File     :  /data/lua/cybranprojectiles.lua
--  Author(s): John Comes, Gordon Duclos
--  Summary  :
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------

--------------------------------------------------------------------------
--  CYBRAN PROJECILES SCRIPTS
--------------------------------------------------------------------------
local DefaultProjectileFile = import("/lua/sim/defaultprojectiles.lua")
local EmitterProjectile = DefaultProjectileFile.EmitterProjectile
local OnWaterEntryEmitterProjectile = DefaultProjectileFile.OnWaterEntryEmitterProjectile
local SingleBeamProjectile = DefaultProjectileFile.SingleBeamProjectile
local SinglePolyTrailProjectile = DefaultProjectileFile.SinglePolyTrailProjectile
local MultiPolyTrailProjectile = DefaultProjectileFile.MultiPolyTrailProjectile
local SingleCompositeEmitterProjectile = DefaultProjectileFile.SingleCompositeEmitterProjectile
local DepthCharge = import("/lua/defaultantiprojectile.lua").DepthCharge
local NullShell = DefaultProjectileFile.NullShell
local EffectTemplate = import("/lua/effecttemplates.lua")
local NukeProjectile = DefaultProjectileFile.NukeProjectile


--------------------------------------------------------------------------
--  CYBRAN BRACKMAN "HACK PEG-POD" PROJECTILE
--------------------------------------------------------------------------
---@class CDFBrackmanHackPegProjectile01 : MultiPolyTrailProjectile
CDFBrackmanHackPegProjectile01 = Class(MultiPolyTrailProjectile) {
    FxImpactTrajectoryAligned = false,
    PolyTrails = EffectTemplate.CBrackmanCrabPegPodTrails,
    PolyTrailOffset = {0,0},

    FxTrails = {},
    FxImpactUnit = {},
    FxImpactProp = {},
    FxImpactLand = {},
    FxTrailOffset = 0,
    FxImpactUnderWater = {},
}

--------------------------------------------------------------------------
--  CYBRAN BRACKMAN "HACK PEG" PROJECTILES
--------------------------------------------------------------------------
---@class CDFBrackmanHackPegProjectile02 : MultiPolyTrailProjectile
CDFBrackmanHackPegProjectile02 = Class(MultiPolyTrailProjectile) {
    FxImpactTrajectoryAligned = false,
    PolyTrails = EffectTemplate.CBrackmanCrabPegTrails,
    PolyTrailOffset = {0,0},

    FxTrails = {},
    FxImpactUnit = {},
    FxImpactProp = {},
    FxImpactLand = EffectTemplate.CBrackmanCrabPegHit01,
    FxTrailOffset = 0,
    FxImpactUnderWater = {},
}

--------------------------------------------------------------------------
--  CYBRAN PROTON PROJECTILES
--------------------------------------------------------------------------

-- T3 strategic bomber
---@class CIFProtonBombProjectile : NullShell
CIFProtonBombProjectile = Class(NullShell) {
    FxImpactTrajectoryAligned = false,
    FxImpactUnit = EffectTemplate.CProtonBombHit01,
    FxImpactProp = EffectTemplate.CProtonBombHit01,
    FxImpactLand = EffectTemplate.CProtonBombHit01,

    ---@param self CIFProtonBombProjectile
    ---@param targetType string
    ---@param targetEntity Unit
    OnImpact = function(self, targetType, targetEntity)

        CreateLightParticle(self, -1, self.Army, 12, 28, 'glow_03', 'ramp_proton_flash_02')
        CreateLightParticle(self, -1, self.Army, 8, 22, 'glow_03', 'ramp_antimatter_02')

        local blanketSides = 12
        local blanketAngle = (2*math.pi) / blanketSides
        local blanketStrength = 1
        local blanketVelocity = 6.25

        for i = 0, (blanketSides-1) do
            local blanketX = math.sin(i*blanketAngle)
            local blanketZ = math.cos(i*blanketAngle)
            self:CreateProjectile('/effects/entities/EffectProtonAmbient01/EffectProtonAmbient01_proj.bp', blanketX, 0.5, blanketZ, blanketX, 0, blanketZ)
                :SetVelocity(blanketVelocity):SetAcceleration(-0.3)
        end

        NullShell.OnImpact(self, targetType, targetEntity)
    end,
}

--------------------------------------------------------------------------
--  CYBRAN PROTON PROJECTILES
--------------------------------------------------------------------------
---@class CDFProtonCannonProjectile : MultiPolyTrailProjectile
CDFProtonCannonProjectile = Class(MultiPolyTrailProjectile) {
    PolyTrails = {
        EffectTemplate.CProtonCannonPolyTrail,
        '/effects/emitters/default_polytrail_01_emit.bp',
    },
    PolyTrailOffset = {0,0},

    FxTrails = EffectTemplate.CProtonCannonFXTrail01,
    -- PolyTrail = EffectTemplate.CProtonCannonPolyTrail,
    FxImpactUnit = EffectTemplate.CProtonCannonHit01,
    FxImpactProp = EffectTemplate.CProtonCannonHit01,
    FxImpactLand = EffectTemplate.CProtonCannonHit01,
    FxTrailOffset = 0,
    FxImpactUnderWater = {},
}

---- XRL0403 experimental crab heavy proton cannon
---@class CDFHvyProtonCannonProjectile : MultiPolyTrailProjectile
CDFHvyProtonCannonProjectile = Class(MultiPolyTrailProjectile) {
    PolyTrails = {
        EffectTemplate.CHvyProtonCannonPolyTrail,
        '/effects/emitters/default_polytrail_01_emit.bp',
    },
    PolyTrailOffset = {0,0},

    FxTrails = EffectTemplate.CHvyProtonCannonFXTrail01,
    -- PolyTrail = EffectTemplate.CHvyProtonCannonPolyTrail,
    FxImpactUnit = EffectTemplate.CHvyProtonCannonHitUnit,
    FxImpactProp = EffectTemplate.CHvyProtonCannonHitUnit,
    FxImpactLand = EffectTemplate.CHvyProtonCannonHitLand,
    FxImpactUnderWater = EffectTemplate.CHvyProtonCannonHit01,
    FxImpactWater = EffectTemplate.CHvyProtonCannonHit01,
    FxTrailOffset = 0,    
}

--------------------------------------------------------------------------
--  CYBRAN DISSIDENT PROJECTILE
--------------------------------------------------------------------------
---@class CAADissidentProjectile : SinglePolyTrailProjectile
CAADissidentProjectile = Class(SinglePolyTrailProjectile) {

    PolyTrail = '/effects/emitters/electron_bolter_trail_01_emit.bp',
    FxTrails = {'/effects/emitters/electron_bolter_munition_01_emit.bp',},

    -- Hit Effects
    FxImpactUnit = EffectTemplate.TMissileHit01,
    FxImpactProp = EffectTemplate.TMissileHit01,
    FxImpactLand = EffectTemplate.TMissileHit01,
    FxImpactProjectile = EffectTemplate.TMissileHit01,
}

--------------------------------------------------------------------------
--  ELECTRON BURST CLOUD PROJECILE
--------------------------------------------------------------------------
---@class CAAElectronBurstCloudProjectile : SinglePolyTrailProjectile
CAAElectronBurstCloudProjectile = Class(SinglePolyTrailProjectile) {

    PolyTrail = '/effects/emitters/default_polytrail_02_emit.bp',

    -- Hit Effects
    FxImpactLand = {},
    FxImpactWater = {},
    FxImpactUnderWater = {},
    FxImpactAirUnit = EffectTemplate.CElectronBurstCloud01,
    FxImpactNone = EffectTemplate.CElectronBurstCloud01,
}

--------------------------------------------------------------------------
--  NANITE MISSILE PROJECTILE
--------------------------------------------------------------------------
---@class CAAMissileNaniteProjectile : SingleCompositeEmitterProjectile
CAAMissileNaniteProjectile = Class(SingleCompositeEmitterProjectile) {
    -- Emitter Values
    FxTrails = {},
    FxTrailOffset = -0.05,
    PolyTrail =  EffectTemplate.CNanoDartPolyTrail01, ------'/effects/emitters/caamissilenanite01_polytrail_01_emit.bp',
    BeamName = '/effects/emitters/missile_nanite_exhaust_beam_01_emit.bp',

    -- Hit Effects
    FxUnitHitScale = 0.5,
    FxImpactAirUnit = EffectTemplate.CNanoDartUnitHit01,
    FxImpactNone = EffectTemplate.CNanoDartUnitHit01,
    FxImpactUnit = EffectTemplate.CNanoDartUnitHit01,
    FxImpactProp = EffectTemplate.CNanoDartUnitHit01,
    FxLandHitScale = 0.5,
    FxImpactLand = EffectTemplate.CMissileHit01,
    FxImpactUnderWater = {},
}

---@class CAAMissileNaniteProjectile03 : CAAMissileNaniteProjectile
CAAMissileNaniteProjectile03 = Class(CAAMissileNaniteProjectile) {
    -- PolyTrail = '/effects/emitters/caamissilenanite01_polytrail_02_emit.bp',
}

--------------------------------------------------------------------------
--  NANODART PROJECILE
--------------------------------------------------------------------------
---@class CAANanoDartProjectile : SinglePolyTrailProjectile
CAANanoDartProjectile = Class(SinglePolyTrailProjectile) {
    FxImpactTrajectoryAligned = false,

    PolyTrail= EffectTemplate.CNanoDartPolyTrail01,

    -- Hit Effects
    FxImpactAirUnit = EffectTemplate.CNanoDartUnitHit01,
    FxImpactUnit = EffectTemplate.CNanoDartUnitHit01,
    FxImpactLand = EffectTemplate.CNanoDartLandHit01,
    FxImpactWater = {},
    FxImpactUnderWater = {},
}

---@class CAANanoDartProjectile02 : CAANanoDartProjectile
CAANanoDartProjectile02 = Class(CAANanoDartProjectile) {
    PolyTrail= EffectTemplate.CNanoDartPolyTrail02,
}

-- adjustment to cheapen effects for URL0104
---@class CAANanoDartProjectile03 : CAANanoDartProjectile
CAANanoDartProjectile03 = Class(CAANanoDartProjectile) {
    FxImpactAirUnit = EffectTemplate.CNanoDartUnitHit02,
    FxImpactUnit = EffectTemplate.CNanoDartUnitHit02,
    FxImpactLand = EffectTemplate.CNanoDartLandHit02,
}

--------------------------------------------------------------------------
--  CYBRAN ARTILLERY PROJECILES
--------------------------------------------------------------------------
---@class CArtilleryProjectile : EmitterProjectile
CArtilleryProjectile = Class(EmitterProjectile) {
    FxTrails = {'/effects/emitters/mortar_munition_03_emit.bp',},

    -- Hit Effects
    FxImpactUnit = EffectTemplate.CNanoDartUnitHit01,
    FxImpactProp = EffectTemplate.CArtilleryHit01,
    FxImpactLand = EffectTemplate.CArtilleryHit01,
    FxImpactUnderWater = {},
}

---@class CArtilleryProtonProjectile : SinglePolyTrailProjectile
CArtilleryProtonProjectile = Class(SinglePolyTrailProjectile) {
    FxTrails = {},
    FxImpactTrajectoryAligned = false,
    PolyTrail = '/effects/emitters/default_polytrail_01_emit.bp',

    -- Hit Effects
    FxImpactUnit = EffectTemplate.CProtonArtilleryHit01,
    FxImpactProp = EffectTemplate.CProtonArtilleryHit01,
    FxImpactLand = EffectTemplate.CProtonArtilleryHit01,
    FxImpactUnderWater = {},

    ---@param self CArtilleryProjectile
    ---@param targetType string
    ---@param targetEntity Unit
    OnImpact = function(self, targetType, targetEntity)
        EmitterProjectile.OnImpact(self, targetType, targetEntity)

        -- pretty flash
        CreateLightParticle( self, -1, self.Army, 7, 12, 'glow_03', 'ramp_red_06' )
        CreateLightParticle( self, -1, self.Army, 7, 22, 'glow_03', 'ramp_antimatter_02' )
    end,
}

--------------------------------------------------------------------------
--  CYBRAN BEAM PROJECILES
--------------------------------------------------------------------------
---@class CBeamProjectile : NullShell
CBeamProjectile = Class(NullShell) {
    FxUnitHitScale = 0.5,
    FxImpactUnit = EffectTemplate.CBeamHitUnit01,
    FxImpactProp = EffectTemplate.CBeamHitUnit01,
    FxImpactLand = EffectTemplate.CBeamHitLand01,
    FxImpactUnderWater = {},
}

--------------------------------------------------------------------------
--  CYBRAN BOMBs
--------------------------------------------------------------------------
---@class CBombProjectile : EmitterProjectile
CBombProjectile = Class(EmitterProjectile) {
    FxTrails = {'/effects/emitters/bomb_munition_plasma_aeon_01_emit.bp'},

    -- Hit Effects
    FxImpactUnit = EffectTemplate.CBombHit01,
    FxImpactProp = EffectTemplate.CBombHit01,
    FxImpactLand = EffectTemplate.CBombHit01,
    FxImpactUnderWater = {},
}

--------------------------------------------------------------------------
--  CYBRAN SHIP PROJECILES
--------------------------------------------------------------------------
---@class CCannonSeaProjectile : SingleBeamProjectile
CCannonSeaProjectile = Class(SingleBeamProjectile) {
    BeamName = '/effects/emitters/cannon_munition_ship_cybran_beam_01_emit.bp',
    FxImpactUnderWater = {},
}

---------------------------------------------------------------------
--  CYBRAN TANK CANNON PROJECILES
--------------------------------------------------------------------------
---@class CCannonTankProjectile : SingleBeamProjectile
CCannonTankProjectile = Class(SingleBeamProjectile) {
    BeamName = '/effects/emitters/cannon_munition_ship_cybran_beam_01_emit.bp',
    FxImpactUnderWater = {},
}

-----------------------------
--  CYBRAN TRACKER PROJECILES
-----------------------------
---@class CDFTrackerProjectile : SingleCompositeEmitterProjectile
CDFTrackerProjectile = Class(SingleCompositeEmitterProjectile) {
    -- Emitter Values
    FxInitial = {},
    TrailDelay = 1,
    FxTrails = {'/effects/emitters/missile_sam_munition_trail_01_emit.bp',},
    FxTrailOffset = 0.5,

    BeamName = '/effects/emitters/missile_sam_munition_exhaust_beam_01_emit.bp',

    -- Hit Effects
    FxUnitHitScale = 0.5,
    FxImpactUnit = {},
    FxLandHitScale = 0.5,
    FxImpactLand = EffectTemplate.CMissileHit01,
    FxImpactUnderWater = {},
}

--------------------------------------------------------------------------
--  DISINTEGRATOR LASER PROJECILE
--------------------------------------------------------------------------

--loya & wailers
---@class CDisintegratorLaserProjectile : MultiPolyTrailProjectile
CDisintegratorLaserProjectile = Class(MultiPolyTrailProjectile) {
    PolyTrails = {
        '/effects/emitters/disintegrator_polytrail_04_emit.bp',
        '/effects/emitters/disintegrator_polytrail_05_emit.bp',
        '/effects/emitters/default_polytrail_03_emit.bp',
    },
    PolyTrailOffset = {0,0,0},
    FxTrails = EffectTemplate.CDisintegratorFxTrails01,

    -- Hit Effects
    FxImpactUnit = EffectTemplate.CDisintegratorHitUnit01,
    FxImpactAirUnit = EffectTemplate.CDisintegratorHitAirUnit01,
    FxImpactProp = EffectTemplate.CDisintegratorHitUnit01,
    FxImpactLand = EffectTemplate.CDisintegratorHitLand01,
    FxImpactUnderWater = {},
}

-- adjusments for URA0104 to tone down effect
---@class CDisintegratorLaserProjectile02 : MultiPolyTrailProjectile
CDisintegratorLaserProjectile02 = Class(MultiPolyTrailProjectile) {
    PolyTrails = {
        '/effects/emitters/disintegrator_polytrail_04_emit.bp',
        '/effects/emitters/disintegrator_polytrail_05_emit.bp',
        '/effects/emitters/default_polytrail_03_emit.bp',
    },
    PolyTrailOffset = {0,0,0},

    -- Hit Effects
    FxImpactUnit = EffectTemplate.CDisintegratorHitUnit01,
    FxImpactAirUnit = EffectTemplate.CDisintegratorHitAirUnit01,
    FxImpactProp = EffectTemplate.CDisintegratorHitUnit01,
    FxImpactLand = EffectTemplate.CDisintegratorHitLand01,
    FxImpactUnderWater = {},
}

--------------------------------------------------------------------------
--  CYBRAN ELECTRON BOLTER PROJECILES
--------------------------------------------------------------------------

-- loya, wagner, monkeylord & soul ripper
---@class CElectronBolterProjectile : MultiPolyTrailProjectile
CElectronBolterProjectile = Class(MultiPolyTrailProjectile) {

    PolyTrails = {
        '/effects/emitters/electron_bolter_trail_02_emit.bp',
        '/effects/emitters/default_polytrail_01_emit.bp',
    },
    PolyTrailOffset = {0,0},
    FxTrails = {'/effects/emitters/electron_bolter_munition_01_emit.bp',},

    -- Hit Effects
    FxImpactUnit = EffectTemplate.CElectronBolterHitUnit01,
    FxImpactProp = EffectTemplate.CElectronBolterHitUnit01,
    FxImpactLand = EffectTemplate.CElectronBolterHitLand01,
}

-- SoulRipper
---@class CHeavyElectronBolterProjectile : MultiPolyTrailProjectile
CHeavyElectronBolterProjectile = Class(MultiPolyTrailProjectile) {

    PolyTrails = {
        '/effects/emitters/electron_bolter_trail_01_emit.bp',
        '/effects/emitters/default_polytrail_05_emit.bp',
    },
    PolyTrailOffset = {0,0},
    FxTrails = {'/effects/emitters/electron_bolter_munition_02_emit.bp',},

    -- Hit Effects
    FxImpactUnit = EffectTemplate.CElectronBolterHitUnit02,
    FxImpactProp = EffectTemplate.CElectronBolterHitUnit02,
    FxImpactLand = EffectTemplate.CElectronBolterHitLand02,

    FxAirUnitHitScale = 2.5,
    FxLandHitScale = 2.5,
    FxNoneHitScale = 2.5,
    FxPropHitScale = 2.5,
    FxProjectileHitScale = 2.5,
    FxShieldHitScale = 2.5,
    FxUnitHitScale = 2.5,
    FxWaterHitScale = 2.5,
    FxOnKilledScale = 2.5,
}

--------------------------------------------------------------------------
--  TERRAN SUB-LAUNCHED CRUISE MISSILE PROJECTILES
--------------------------------------------------------------------------
---@class CEMPFluxWarheadProjectile : NukeProjectile
CEMPFluxWarheadProjectile = Class(NukeProjectile, SingleBeamProjectile) {
    BeamName = '/effects/emitters/missile_exhaust_fire_beam_01_emit.bp',
    FxInitialAtEntityEmitter = {},
    FxUnderWaterTrail = {'/effects/emitters/missile_cruise_munition_underwater_trail_01_emit.bp',},
    FxOnEntityEmitter = {},
    FxExitWaterEmitter = EffectTemplate.DefaultProjectileWaterImpact,
    FxSplashScale = 0.65,
    ExitWaterTicks = 9,
    FxTrailOffset = -0.5,

    -- LAUNCH TRAILS
    FxLaunchTrails = {},

    -- TRAILS
    FxTrails = {'/effects/emitters/missile_cruise_munition_trail_01_emit.bp',},

    -- Hit Effects
    FxImpactUnit = {},
    FxImpactLand = {},
    FxImpactUnderWater = {},
}

--------------------------------------------------------------------------
--  CYBRAN FLAME THROWER PROJECTILES
--------------------------------------------------------------------------
---@class CFlameThrowerProjectile : EmitterProjectile
CFlameThrowerProjectile = Class(EmitterProjectile) {
    FxTrails = {'/effects/emitters/flamethrower_02_emit.bp'},
    FxTrailScale = 1,
    FxTrailOffset = 0,
    FxImpactUnderWater = {},
}

--------------------------------------------------------------------------
--  CYBRAN MOLECULAR RESONANCE SHELL PROJECTILE
--------------------------------------------------------------------------
---@class CIFMolecularResonanceShell : SinglePolyTrailProjectile
CIFMolecularResonanceShell = Class(SinglePolyTrailProjectile) {

    PolyTrail = '/effects/emitters/default_polytrail_01_emit.bp',

    -- Hit Effects
    FxImpactUnit = EffectTemplate.CMolecularResonanceHitUnit01,
    FxImpactProp = EffectTemplate.CMolecularResonanceHitUnit01,
    FxImpactLand = EffectTemplate.CMolecularResonanceHitUnit01,
    FxImpactUnderWater = {},
    DestroyOnImpact = false,

    ---@param self CIFMolecularResonanceShell
    OnCreate = function(self)
        SinglePolyTrailProjectile.OnCreate(self)
        self.Impacted = false
    end,

    ---@param self CIFMolecularResonanceShell
    DelayedDestroyThread = function(self)
        WaitSeconds(0.3)
        self:CreateImpactEffects(self.Army, self.FxImpactUnit, self.FxUnitHitScale)
        self:Destroy()
    end,

    ---@param self CIFMolecularResonanceShell
    ---@param TargetType string
    ---@param TargetEntity Unit
    OnImpact = function(self, TargetType, TargetEntity)
        if self.Impacted == false then
            self.Impacted = true
            if TargetType == 'Terrain' then
                SinglePolyTrailProjectile.OnImpact(self, TargetType, TargetEntity)
                self:ForkThread(self.DelayedDestroyThread)
            else
                SinglePolyTrailProjectile.OnImpact(self, TargetType, TargetEntity)
                self:Destroy()
            end
        end
    end,
}

--------------------------------------------------------------------------
--  IRIDIUM ROCKET PROJECTILES
--------------------------------------------------------------------------

-- T2 gs & SR & hoplite
---@class CIridiumRocketProjectile : SingleCompositeEmitterProjectile
CIridiumRocketProjectile = Class(SingleCompositeEmitterProjectile) {
    FxTrails = {},
    PolyTrail = '/effects/emitters/cybran_iridium_missile_polytrail_01_emit.bp',
    BeamName = '/effects/emitters/rocket_iridium_exhaust_beam_01_emit.bp',
    FxImpactUnit = EffectTemplate.CMissileHit02,
    FxImpactProp = EffectTemplate.CMissileHit02,
    FxImpactLand = EffectTemplate.CMissileHit02,
    FxImpactUnderWater = {},
}

--------------------------------------------------------------------------
--  CORSAIR MISSILE PROJECTILES
--------------------------------------------------------------------------
---@class CCorsairRocketProjectile : SingleCompositeEmitterProjectile
CCorsairRocketProjectile = Class(SingleCompositeEmitterProjectile) {
    FxTrails = {},
    PolyTrail = EffectTemplate.CCorsairMissilePolyTrail01,
    BeamName = '/effects/emitters/rocket_iridium_exhaust_beam_01_emit.bp',
    FxImpactUnit = EffectTemplate.CCorsairMissileUnitHit01,
    FxImpactProp = EffectTemplate.CCorsairMissileHit01,
    FxImpactLand = EffectTemplate.CCorsairMissileLandHit01,
    FxImpactUnderWater = {},
}

--------------------------------------------------------------------------
--  CYBRAN LASER PROJECILES
--------------------------------------------------------------------------
---@class CLaserLaserProjectile : MultiPolyTrailProjectile
CLaserLaserProjectile = Class(MultiPolyTrailProjectile) {
    PolyTrails = {
        '/effects/emitters/cybran_laser_trail_01_emit.bp',
        '/effects/emitters/default_polytrail_02_emit.bp',
    },
    PolyTrailOffset = {0,0},

    -- Hit Effects
    FxImpactUnit = EffectTemplate.CLaserHitUnit01,
    FxImpactProp = EffectTemplate.CLaserHitUnit01,
    FxImpactLand = EffectTemplate.CLaserHitLand01,
    FxImpactUnderWater = {},
}

---@class CHeavyLaserProjectile : MultiPolyTrailProjectile
CHeavyLaserProjectile = Class(MultiPolyTrailProjectile) {
    PolyTrails = {
        '/effects/emitters/cybran_laser_trail_02_emit.bp',
        '/effects/emitters/default_polytrail_03_emit.bp',
    },
    PolyTrailOffset = {0,0},

    -- Hit Effects
    FxImpactUnit = EffectTemplate.CLaserHitUnit01,
    FxImpactProp = EffectTemplate.CLaserHitUnit01,
    FxImpactLand = EffectTemplate.CLaserHitLand01,
    FxImpactUnderWater = {},
}

---@class CHeavyLaserProjectile2 : MultiPolyTrailProjectile
CHeavyLaserProjectile2 = Class(MultiPolyTrailProjectile) {
    PolyTrails = {
        '/effects/emitters/hrailgunsd_polytrail_01_emit.bp',
                '/effects/emitters/default_polytrail_02_emit.bp',
    },
    PolyTrailOffset = {0,0},

    -- Hit Effects
    FxUnitHitScale = 0.15,
    FxLandHitScale = 0.15,
    FxImpactUnit = EffectTemplate.CBeamHitUnit01,
    FxImpactProp = EffectTemplate.CBeamHitUnit01,
    FxImpactLand = EffectTemplate.CBeamHitLand01,
    FxImpactUnderWater = {},
}

--------------------------------------------------------------------------
--  CYBRAN MOLECULAR CANNON PROJECTILE
--------------------------------------------------------------------------

-- ACU
---@class CMolecularCannonProjectile : SinglePolyTrailProjectile
CMolecularCannonProjectile = Class(SinglePolyTrailProjectile) {
    FxImpactTrajectoryAligned = false,
    PolyTrail = '/effects/emitters/default_polytrail_03_emit.bp',
    FxTrails = EffectTemplate.CMolecularCannon01,

    -- Hit Effects
    FxImpactUnit = EffectTemplate.CMolecularRipperHit01,
    FxImpactProp = EffectTemplate.CMolecularRipperHit01,
    FxImpactLand = EffectTemplate.CMolecularRipperHit01,
}

--------------------------------------------------------------------------
--  CYBRAN AA MISSILE PROJECILES - Air Targets
--------------------------------------------------------------------------
---@class CMissileAAProjectile : SingleCompositeEmitterProjectile
CMissileAAProjectile = Class(SingleCompositeEmitterProjectile) {
    -- Emitter Values
    FxInitial = {},
    TrailDelay = 1,
    FxTrails = {'/effects/emitters/missile_sam_munition_trail_01_emit.bp',},
    FxTrailOffset = 0.5,

    BeamName = '/effects/emitters/missile_sam_munition_exhaust_beam_01_emit.bp',

    -- Hit Effects
    FxUnitHitScale = 0.5,
    FxImpactUnit = EffectTemplate.CMissileHit01,
    FxImpactProp = EffectTemplate.CMissileHit01,
    FxLandHitScale = 0.5,
    FxImpactLand = EffectTemplate.CMissileHit01,
    FxImpactUnderWater = {},

    OnCreate = function(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)
        SingleBeamProjectile.OnCreate(self)
    end,
}

--------------------------------------------------------------------------
--  NEUTRON CLUSTER BOMB PROJECTILES
--------------------------------------------------------------------------
---@class CNeutronClusterBombChildProjectile : SinglePolyTrailProjectile
CNeutronClusterBombChildProjectile = Class(SinglePolyTrailProjectile) {
    FxTrails = {},
    PolyTrail = '/effects/emitters/default_polytrail_05_emit.bp',

    -- Hit Effects
    FxImpactUnit = EffectTemplate.CNeutronClusterBombHitUnit01,
    FxImpactProp = EffectTemplate.CNeutronClusterBombHitUnit01,
    FxImpactLand = EffectTemplate.CNeutronClusterBombHitLand01,
    FxImpactWater = EffectTemplate.CNeutronClusterBombHitWater01,
    FxImpactUnderWater = {},

    -- No damage dealt by this child.
    ---@param self CNeutronClusterBombChildProjectile
    ---@param instigator Weapon
    ---@param damageData table
    ---@param targetEntity Unit
    DoDamage = function(self, instigator, damageData, targetEntity)
    end,
}

---@class CNeutronClusterBombProjectile : SinglePolyTrailProjectile
CNeutronClusterBombProjectile = Class(SinglePolyTrailProjectile) {
    FxTrails = {},
    PolyTrail = '/effects/emitters/default_polytrail_03_emit.bp',

    -- Hit Effects
    FxImpactUnit = {},
    FxImpactLand = {},
    FxImpactUnderWater = {},

    ChildProjectile = '/projectiles/CIFNeutronClusterBomb02/CIFNeutronClusterBomb02_proj.bp',

    ---@param self CNeutronClusterBombProjectile
    OnCreate = function(self)
        SinglePolyTrailProjectile.OnCreate(self)
        self.Impacted = false
    end,

    --- Note: Damage is done once in AOE by main projectile. Secondary projectiles
    --- are just visual.
    ---@param self CNeutronClusterBombProjectile
    ---@param targetType string
    ---@param targetEntity Unit
    OnImpact = function(self, targetType, targetEntity)
        if self.Impacted == false and targetType ~= 'Air' then
            self.Impacted = true
            local Random = Random 
            self:CreateChildProjectile(self.ChildProjectile):SetVelocity(0,Random(1,3),Random(1.5,3))
            self:CreateChildProjectile(self.ChildProjectile):SetVelocity(Random(1,2),Random(1,3),Random(1,2))
            self:CreateChildProjectile(self.ChildProjectile):SetVelocity(0,Random(1,3),-Random(1.5,3))
            self:CreateChildProjectile(self.ChildProjectile):SetVelocity(Random(1.5,3),Random(1,3),0)
            self:CreateChildProjectile(self.ChildProjectile):SetVelocity(-Random(1,2),Random(1,3),-Random(1,2))
            self:CreateChildProjectile(self.ChildProjectile):SetVelocity(-Random(1.5,2.5),Random(1,3),0)
            self:CreateChildProjectile(self.ChildProjectile):SetVelocity(-Random(1,2),Random(1,3),Random(2,4))
            SinglePolyTrailProjectile.OnImpact(self, targetType, targetEntity)
        end
    end,

    --- Overiding Destruction
    ---@param self CNeutronClusterBombProjectile
    ---@param targetType string
    ---@param targetEntity Unit
    OnImpactDestroy = function(self, targetType, targetEntity)
        self:ForkThread(self.DelayedDestroyThread)
    end,

    ---@param self CNeutronClusterBombProjectile
    DelayedDestroyThread = function(self)
        WaitSeconds(0.5)
        self:Destroy()
    end,
}

--------------------------------------------------------------------------
--  CYBRAN MACHINE GUN SHELLS
--------------------------------------------------------------------------
---@class CParticleCannonProjectile : SingleBeamProjectile
CParticleCannonProjectile = Class(SingleBeamProjectile) {
    BeamName = '/effects/emitters/laserturret_munition_beam_01_emit.bp',

    -- Hit Effects
    FxImpactUnit = EffectTemplate.CParticleCannonHitUnit01,
    FxImpactProp = EffectTemplate.CParticleCannonHitUnit01,
    FxImpactLand = EffectTemplate.CParticleCannonHitLand01,
    FxImpactUnderWater = {},
}

--------------------------------------------------------------------------
--  CYBRAN RAIL GUN PROJECTILES
--------------------------------------------------------------------------
---@class CRailGunProjectile : EmitterProjectile
CRailGunProjectile = Class(EmitterProjectile) {
    FxTrails = {'/effects/emitters/railgun_munition_trail_02_emit.bp',
                '/effects/emitters/railgun_munition_trail_01_emit.bp'},
    FxTrailScale = 0,
    FxTrailOffset = 0,
    FxImpactUnderWater = {},
}

--------------------------------------------------------------------------
--  CYBRAN ROCKET PROJECILES
--------------------------------------------------------------------------

-- wagner
---@class CRocketProjectile : SingleBeamProjectile
CRocketProjectile = Class(SingleBeamProjectile) {
    -- Emitter Values
    BeamName = '/effects/emitters/rocket_iridium_exhaust_beam_01_emit.bp',

    -- Hit Effects
    FxImpactUnit = EffectTemplate.CMissileHit01,
    FxImpactProp = EffectTemplate.CMissileHit01,
    FxImpactLand = EffectTemplate.CMissileHit01,
    FxImpactUnderWater = {},
}

---@class CLOATacticalMissileProjectile : SingleBeamProjectile
CLOATacticalMissileProjectile = Class(SingleBeamProjectile) {

    BeamName = '/effects/emitters/missile_loa_munition_exhaust_beam_01_emit.bp',
    FxTrails = {'/effects/emitters/missile_cruise_munition_trail_01_emit.bp',},
    FxTrailOffset = -0.5,
    FxExitWaterEmitter = EffectTemplate.TIFCruiseMissileLaunchExitWater,

    -- Hit Effects
    FxImpactUnit = EffectTemplate.CMissileLOAHit01,
    FxImpactLand = EffectTemplate.CMissileLOAHit01,
    FxImpactProp = EffectTemplate.CMissileLOAHit01,
    FxImpactNone = EffectTemplate.CMissileLOAHit01,
    FxImpactUnderWater = {},
}

---@class CLOATacticalChildMissileProjectile : SingleBeamProjectile
CLOATacticalChildMissileProjectile = Class(SingleBeamProjectile) {
    BeamName = '/effects/emitters/missile_loa_munition_exhaust_beam_02_emit.bp',
    FxTrails = {'/effects/emitters/missile_cruise_munition_trail_03_emit.bp',},
    FxTrailOffset = -0.5,
    FxExitWaterEmitter = EffectTemplate.TIFCruiseMissileLaunchExitWater,

    -- Hit Effects
    FxImpactUnit = EffectTemplate.CMissileLOAHit01,
    FxImpactLand = EffectTemplate.CMissileLOAHit01,
    FxImpactProp = EffectTemplate.CMissileLOAHit01,
    FxImpactUnderWater = {},
    FxImpactNone = EffectTemplate.CMissileLOAHit01,
    FxAirUnitHitScale = 0.375,
    FxLandHitScale = 0.375,
    FxNoneHitScale = 0.375,
    FxPropHitScale = 0.375,
    FxProjectileHitScale = 0.375,
    FxShieldHitScale = 0.375,
    FxUnitHitScale = 0.375,
    FxWaterHitScale = 0.375,
    FxOnKilledScale = 0.375,

    ---@param self CLOATacticalChildMissileProjectile
    OnCreate = function(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)
        SingleBeamProjectile.OnCreate(self)
    end,

    ---@param self CLOATacticalChildMissileProjectile
    ---@param targetType string
    ---@param targetEntity Unit
    OnImpact = function(self, targetType, targetEntity)
        CreateLightParticle(self, -1, self.Army, 1, 7, 'glow_03', 'ramp_fire_11')
        SingleBeamProjectile.OnImpact(self, targetType, targetEntity)
    end,

    ---@param self CLOATacticalChildMissileProjectile
    ---@param army number
    ---@param EffectTable table
    ---@param EffectScale? number
    CreateImpactEffects = function(self, army, EffectTable, EffectScale)
        local emit = nil
        for k, v in EffectTable do
            emit = CreateEmitterAtEntity(self, army, v)
            if emit and EffectScale ~= 1 then
                emit:ScaleEmitter(EffectScale or 1)
            end
        end
    end,
}

--------------------------------------------------------------------------
--  CYBRAN AUTOCANNON PROJECILES
--------------------------------------------------------------------------
---@class CShellAAAutoCannonProjectile : MultiPolyTrailProjectile
CShellAAAutoCannonProjectile = Class(MultiPolyTrailProjectile) {
    PolyTrails = {
        '/effects/emitters/auto_cannon_trail_01_emit.bp',
        '/effects/emitters/default_polytrail_03_emit.bp',
    },
    PolyTrailOffset = {0,0},

    -- Hit Effects
    FxImpactUnit = {'/effects/emitters/auto_cannon_hit_flash_01_emit.bp', },
    FxImpactProp ={'/effects/emitters/auto_cannon_hit_flash_01_emit.bp', },
    FxImpactAirUnit = {'/effects/emitters/auto_cannon_hit_flash_01_emit.bp', },
    FxImpactLand = {},
    FxImpactWater = {},
    FxImpactUnderWater = {},
}

--------------------------------------------------------------------------
--  CYBRAN RIOT PROJECILES
--------------------------------------------------------------------------
---@class CShellRiotProjectile : SingleBeamProjectile
CShellRiotProjectile = Class(SingleBeamProjectile) {
    BeamName = '/effects/emitters/riotgun_munition_beam_01_emit.bp',

    -- Hit Effects
    FxImpactUnit = {'/effects/emitters/destruction_explosion_sparks_01_emit.bp',},
    FxImpactProp = {'/effects/emitters/destruction_explosion_sparks_01_emit.bp',},
    FxLandHitScale = 3,
    FxImpactLand = {'/effects/emitters/destruction_land_hit_puff_01_emit.bp',},
    FxImpactUnderWater = {},
}

--------------------------------------------------------------------------
--  CYBRAN ABOVE WATER LAUNCHED TORPEDO
--------------------------------------------------------------------------
---@class CTorpedoShipProjectile : OnWaterEntryEmitterProjectile
CTorpedoShipProjectile = Class(OnWaterEntryEmitterProjectile) {
    FxSplashScale = 0.5,
    FxTrails = {'/effects/emitters/torpedo_munition_trail_01_emit.bp',},
    FxTrailScale = 1.25,
    FxTrailOffset = 0.2,
    FxEnterWater= { '/effects/emitters/water_splash_ripples_ring_01_emit.bp',
                    '/effects/emitters/water_splash_plume_01_emit.bp',},

    -- Hit Effects
    FxUnitHitScale = 1.25,
    FxImpactUnit = EffectTemplate.CTorpedoUnitHit01,
    FxImpactProp = EffectTemplate.CTorpedoUnitHit01,
    FxImpactUnderWater = EffectTemplate.CTorpedoUnitHit01,
    FxImpactLand = {},
    FxImpactNone = {},

    ---@param self CTorpedoShipProjectile
    ---@param inWater boolean
    OnCreate = function(self, inWater)
        OnWaterEntryEmitterProjectile.OnCreate(self, inWater)
        -- if we are starting in the water then immediately switch to tracking in water
        if inWater == true then
            self:TrackTarget(true):StayUnderwater(true)
            self:OnEnterWater(self)
        end
    end,

    ---@param self CTorpedoShipProjectile
    OnEnterWater = function(self)
        OnWaterEntryEmitterProjectile.OnEnterWater(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)
    end,

}

--------------------------------------------------------------------------
--  CYBRAN SUB LAUNCHED TORPEDO
--------------------------------------------------------------------------
---@class CTorpedoSubProjectile : EmitterProjectile
CTorpedoSubProjectile = Class(EmitterProjectile) {
    FxTrails = {'/effects/emitters/torpedo_underwater_wake_02_emit.bp',},

    -- Hit Effects
    FxUnitHitScale = 1.25,
    FxImpactUnit = EffectTemplate.CTorpedoUnitHit01,
    FxImpactProp = EffectTemplate.CTorpedoUnitHit01,
    FxImpactUnderWater = EffectTemplate.CTorpedoUnitHit01,
    FxImpactLand = EffectTemplate.CTorpedoUnitHit01,
    FxLandHitScale = 0.25,
    FxNoneHitScale = 1,
    FxImpactNone = {},

    ---@param self CTorpedoSubProjectile
    ---@param inWater boolean
    OnCreate = function(self, inWater)
        self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)
        EmitterProjectile.OnCreate(self, inWater)
    end,
}

--------------------------------------------------------------------------
--  Cybran DEPTH CHARGE PROJECTILES
--------------------------------------------------------------------------
---@class CDepthChargeProjectile : OnWaterEntryEmitterProjectile
CDepthChargeProjectile = Class(OnWaterEntryEmitterProjectile) {
    FxInitial = {},
    FxTrails = {
        '/effects/emitters/anti_torpedo_flare_01_emit.bp',
        '/effects/emitters/anti_torpedo_flare_02_emit.bp',
    },

    -- Hit Effects
    FxImpactLand = {},
    FxImpactUnit = EffectTemplate.CAntiTorpedoHit01,
    FxImpactProp = EffectTemplate.CAntiTorpedoHit01,
    FxImpactUnderWater = EffectTemplate.CAntiTorpedoHit01,
    FxImpactProjectile = EffectTemplate.CAntiTorpedoHit01,
    FxImpactNone = EffectTemplate.CAntiTorpedoHit01,
    FxOnKilled = EffectTemplate.CAntiTorpedoHit01,
    FxEnterWater= EffectTemplate.WaterSplash01,

    ---@param self CDepthChargeProjectile
    ---@param inWater boolean
    OnCreate = function(self, inWater)
        OnWaterEntryEmitterProjectile.OnCreate(self)
        if inWater then
            for i in self.FxTrails do
                CreateEmitterOnEntity(self, self.Army, self.FxTrails[i]):ScaleEmitter(self.FxTrailScale):OffsetEmitter(0, 0, self.FxTrailOffset)
            end
        end

        self:TrackTarget(false)
    end,

    ---@param self CDepthChargeProjectile
    OnEnterWater = function(self)
        OnWaterEntryEmitterProjectile.OnEnterWater(self)

        self:TrackTarget(false)
        self:StayUnderwater(true)
        self:SetTurnRate(0)
        self:SetMaxSpeed(1)
        self:SetVelocity(0, -0.25, 0)
        self:SetVelocity(0.25)
    end,

    ---@param self CDepthChargeProjectile
    ---@param tbl table
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
--
--  SC1 EXPANSION PROJECTILES
--
--------------------------------------------------------------------------

-- Brick
---@class CHeavyDisintegratorPulseLaser : MultiPolyTrailProjectile
CHeavyDisintegratorPulseLaser = Class(MultiPolyTrailProjectile) {
    PolyTrails = {
        '/effects/emitters/disintegrator_polytrail_02_emit.bp',
        '/effects/emitters/disintegrator_polytrail_03_emit.bp',
        '/effects/emitters/default_polytrail_03_emit.bp',
    },
    PolyTrailOffset = {0,0,0},

    -- Hit Effects
    FxImpactUnit = EffectTemplate.CHvyDisintegratorHitUnit01,
    FxImpactProp = EffectTemplate.CHvyDisintegratorHitUnit01,
    FxImpactLand = EffectTemplate.CHvyDisintegratorHitLand01,
    FxImpactUnderWater = {},
    FxTrails = {},
    FxTrailOffset = 0,
}


---@class CKrilTorpedo : OnWaterEntryEmitterProjectile
CKrilTorpedo = Class(OnWaterEntryEmitterProjectile) {
}

-- kept for mod backwards compatibility
local DefaultExplosion = import("/lua/defaultexplosions.lua")
local RandomFloat = import("/lua/utilities.lua").GetRandomFloat
local MultiBeamProjectile = DefaultProjectileFile.MultiBeamProjectile
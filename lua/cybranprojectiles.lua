#****************************************************************************
#**
#**  File     :  /data/lua/cybranprojectiles.lua
#**  Author(s): John Comes, Gordon Duclos
#**
#**  Summary  :
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
#------------------------------------------------------------------------
#  CYBRAN PROJECILES SCRIPTS
#------------------------------------------------------------------------
local DefaultProjectileFile = import('/lua/sim/defaultprojectiles.lua')
local EmitterProjectile = DefaultProjectileFile.EmitterProjectile
local OnWaterEntryEmitterProjectile = DefaultProjectileFile.OnWaterEntryEmitterProjectile
local SingleBeamProjectile = DefaultProjectileFile.SingleBeamProjectile
local MultiBeamProjectile = DefaultProjectileFile.MultiBeamProjectile
local SinglePolyTrailProjectile = DefaultProjectileFile.SinglePolyTrailProjectile
local MultiPolyTrailProjectile = DefaultProjectileFile.MultiPolyTrailProjectile
local SingleCompositeEmitterProjectile = DefaultProjectileFile.SingleCompositeEmitterProjectile
local DepthCharge = import('/lua/defaultantiprojectile.lua').DepthCharge
local NullShell = DefaultProjectileFile.NullShell
local EffectTemplate = import('/lua/EffectTemplates.lua')
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local NukeProjectile = DefaultProjectileFile.NukeProjectile
local DefaultExplosion = import('defaultexplosions.lua')


#------------------------------------------------------------------------
#  CYBRAN BRACKMAN "HACK PEG-POD" PROJECTILE
#------------------------------------------------------------------------
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

#------------------------------------------------------------------------
#  CYBRAN BRACKMAN "HACK PEG" PROJECTILES
#------------------------------------------------------------------------
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

#------------------------------------------------------------------------
#  CYBRAN PROTON PROJECTILES
#------------------------------------------------------------------------
CIFProtonBombProjectile = Class(NullShell) {
    FxImpactTrajectoryAligned = false,
    FxImpactUnit = EffectTemplate.CProtonBombHit01,
    FxImpactProp = EffectTemplate.CProtonBombHit01,
    FxImpactLand = EffectTemplate.CProtonBombHit01,

    OnImpact = function(self, targetType, targetEntity)
        local army = self.Army
        CreateLightParticle(self, -1, army, 12, 28, 'glow_03', 'ramp_proton_flash_02')
        CreateLightParticle(self, -1, army, 8, 22, 'glow_03', 'ramp_antimatter_02')

        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local pos = self:GetPosition()
            local radius = self.DamageData.DamageRadius

            DamageArea(self, pos, radius, 1, 'Force', true)
            DamageArea(self, pos, radius, 1, 'Force', true)
            self.DamageData.DamageAmount = self.DamageData.DamageAmount - 10
            DamageRing(self, pos, 0.1, radius, 10, 'Fire', false, false)
            CreateDecal(pos, RandomFloat(0.0,6.28), 'scorch_011_albedo', '', 'Albedo', 12, 12, 150, 200, army)
        end

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

        EmitterProjectile.OnImpact(self, targetType, targetEntity)
    end,
}

#------------------------------------------------------------------------
#  CYBRAN PROTON PROJECTILES
#------------------------------------------------------------------------
CDFProtonCannonProjectile = Class(MultiPolyTrailProjectile) {
    PolyTrails = {
        EffectTemplate.CProtonCannonPolyTrail,
        '/effects/emitters/default_polytrail_01_emit.bp',
    },
    PolyTrailOffset = {0,0},

    FxTrails = EffectTemplate.CProtonCannonFXTrail01,
    #PolyTrail = EffectTemplate.CProtonCannonPolyTrail,
    FxImpactUnit = EffectTemplate.CProtonCannonHit01,
    FxImpactProp = EffectTemplate.CProtonCannonHit01,
    FxImpactLand = EffectTemplate.CProtonCannonHit01,
    FxTrailOffset = 0,
    FxImpactUnderWater = {},
}

#-- XRL0403 experimental crab heavy proton cannon
CDFHvyProtonCannonProjectile = Class(MultiPolyTrailProjectile) {
    PolyTrails = {
        EffectTemplate.CHvyProtonCannonPolyTrail,
        '/effects/emitters/default_polytrail_01_emit.bp',
    },
    PolyTrailOffset = {0,0},

    FxTrails = EffectTemplate.CHvyProtonCannonFXTrail01,
    #PolyTrail = EffectTemplate.CHvyProtonCannonPolyTrail,
    FxImpactUnit = EffectTemplate.CHvyProtonCannonHitUnit,
    FxImpactProp = EffectTemplate.CHvyProtonCannonHitUnit,
    FxImpactLand = EffectTemplate.CHvyProtonCannonHitLand,
    FxImpactUnderWater = EffectTemplate.CHvyProtonCannonHit01,
    FxImpactWater = EffectTemplate.CHvyProtonCannonHit01,
    FxTrailOffset = 0,
}

#------------------------------------------------------------------------
#  CYBRAN DISSIDENT PROJECTILE
#------------------------------------------------------------------------
CAADissidentProjectile = Class(SinglePolyTrailProjectile) {

    PolyTrail = '/effects/emitters/electron_bolter_trail_01_emit.bp',
    FxTrails = {'/effects/emitters/electron_bolter_munition_01_emit.bp',},

    # Hit Effects
    FxImpactUnit = EffectTemplate.TMissileHit01,
    FxImpactProp = EffectTemplate.TMissileHit01,
    FxImpactLand = EffectTemplate.TMissileHit01,
    FxImpactProjectile = EffectTemplate.TMissileHit01,
}

#------------------------------------------------------------------------
#  ELECTRON BURST CLOUD PROJECILE
#------------------------------------------------------------------------
CAAElectronBurstCloudProjectile = Class(SinglePolyTrailProjectile) {

    PolyTrail = '/effects/emitters/default_polytrail_02_emit.bp',

    # Hit Effects
    FxImpactLand = {},
    FxImpactWater = {},
    FxImpactUnderWater = {},
    FxImpactAirUnit = EffectTemplate.CElectronBurstCloud01,
    FxImpactNone = EffectTemplate.CElectronBurstCloud01,
}

#------------------------------------------------------------------------
#  NANITE MISSILE PROJECTILE
#------------------------------------------------------------------------
CAAMissileNaniteProjectile = Class(SingleCompositeEmitterProjectile) {
# Emitter Values
    FxTrails = {},
    FxTrailOffset = -0.05,
    PolyTrail =  EffectTemplate.CNanoDartPolyTrail01, ###'/effects/emitters/caamissilenanite01_polytrail_01_emit.bp',
    BeamName = '/effects/emitters/missile_nanite_exhaust_beam_01_emit.bp',

    # Hit Effects
    FxUnitHitScale = 0.5,
    FxImpactAirUnit = EffectTemplate.CNanoDartUnitHit01,
    FxImpactNone = EffectTemplate.CNanoDartUnitHit01,
    FxImpactUnit = EffectTemplate.CNanoDartUnitHit01,
    FxImpactProp = EffectTemplate.CNanoDartUnitHit01,
    FxLandHitScale = 0.5,
    FxImpactLand = EffectTemplate.CMissileHit01,
    FxImpactUnderWater = {},
}

CAAMissileNaniteProjectile03 = Class(CAAMissileNaniteProjectile) {
    ###PolyTrail = '/effects/emitters/caamissilenanite01_polytrail_02_emit.bp',
}

#------------------------------------------------------------------------
#  NANODART PROJECILE
#------------------------------------------------------------------------
CAANanoDartProjectile = Class(SinglePolyTrailProjectile) {
    FxImpactTrajectoryAligned = false,

    PolyTrail= EffectTemplate.CNanoDartPolyTrail01,

    # Hit Effects
    FxImpactAirUnit = EffectTemplate.CNanoDartUnitHit01,
    FxImpactUnit = EffectTemplate.CNanoDartUnitHit01,
    FxImpactLand = EffectTemplate.CNanoDartLandHit01,
    FxImpactWater = {},
    FxImpactUnderWater = {},
}

CAANanoDartProjectile02 = Class(CAANanoDartProjectile) {
    PolyTrail= EffectTemplate.CNanoDartPolyTrail02,
}

# adjustment to cheapen effects for URL0104
CAANanoDartProjectile03 = Class(CAANanoDartProjectile) {
    FxImpactAirUnit = EffectTemplate.CNanoDartUnitHit02,
    FxImpactUnit = EffectTemplate.CNanoDartUnitHit02,
    FxImpactLand = EffectTemplate.CNanoDartLandHit02,
}

#------------------------------------------------------------------------
#  CYBRAN ARTILLERY PROJECILES
#------------------------------------------------------------------------
CArtilleryProjectile = Class(EmitterProjectile) {
    FxTrails = {'/effects/emitters/mortar_munition_03_emit.bp',},

    # Hit Effects
    FxImpactUnit = EffectTemplate.CNanoDartUnitHit01,
    FxImpactProp = EffectTemplate.CArtilleryHit01,
    FxImpactLand = EffectTemplate.CArtilleryHit01,
    FxImpactUnderWater = {},
}

CArtilleryProtonProjectile = Class(SinglePolyTrailProjectile) {
    FxTrails = {},
    FxImpactTrajectoryAligned = false,
    PolyTrail = '/effects/emitters/default_polytrail_01_emit.bp',

    -- Hit Effects
    FxImpactUnit = EffectTemplate.CProtonArtilleryHit01,
    FxImpactProp = EffectTemplate.CProtonArtilleryHit01,
    FxImpactLand = EffectTemplate.CProtonArtilleryHit01,
    FxImpactUnderWater = {},

    OnImpact = function(self, targetType, targetEntity)
        local army = self.Army
        local radius = self.DamageData.DamageRadius
        
        CreateLightParticle( self, -1, army, radius * 2, 12, 'glow_03', 'ramp_red_06' )
        CreateLightParticle( self, -1, army, radius * 2, 22, 'glow_03', 'ramp_antimatter_02' )
    
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local pos = self:GetPosition()
            
            DamageArea( self, pos, radius, 1, 'Force', true )
            DamageArea( self, pos, radius, 1, 'Force', true )
            DamageRing( self, pos, radius, 5/4 * radius, 1, 'Fire', true )
            
        end
        
        EmitterProjectile.OnImpact(self, targetType, targetEntity)
    end,
}

#------------------------------------------------------------------------
#  CYBRAN BEAM PROJECILES
#------------------------------------------------------------------------
CBeamProjectile = Class(NullShell) {
    FxUnitHitScale = 0.5,
    FxImpactUnit = EffectTemplate.CBeamHitUnit01,
    FxImpactProp = EffectTemplate.CBeamHitUnit01,
    FxImpactLand = EffectTemplate.CBeamHitLand01,
    FxImpactUnderWater = {},
}

#------------------------------------------------------------------------
#  CYBRAN BOMBs
#------------------------------------------------------------------------
CBombProjectile = Class(EmitterProjectile) {
    FxTrails = {'/effects/emitters/bomb_munition_plasma_aeon_01_emit.bp'},

    # Hit Effects
    FxImpactUnit = EffectTemplate.CBombHit01,
    FxImpactProp = EffectTemplate.CBombHit01,
    FxImpactLand = EffectTemplate.CBombHit01,
    FxImpactUnderWater = {},
}

#------------------------------------------------------------------------
#  CYBRAN SHIP PROJECILES
#------------------------------------------------------------------------
CCannonSeaProjectile = Class(SingleBeamProjectile) {
    BeamName = '/effects/emitters/cannon_munition_ship_cybran_beam_01_emit.bp',
    FxImpactUnderWater = {},
}

#-------------------------------------------------------------------
#  CYBRAN TANK CANNON PROJECILES
#------------------------------------------------------------------------
CCannonTankProjectile = Class(SingleBeamProjectile) {
    BeamName = '/effects/emitters/cannon_munition_ship_cybran_beam_01_emit.bp',
    FxImpactUnderWater = {},
}

#---------------------------
#  CYBRAN TRACKER PROJECILES
#---------------------------
CDFTrackerProjectile = Class(SingleCompositeEmitterProjectile) {
# Emitter Values
    FxInitial = {},
    TrailDelay = 1,
    FxTrails = {'/effects/emitters/missile_sam_munition_trail_01_emit.bp',},
    FxTrailOffset = 0.5,

    BeamName = '/effects/emitters/missile_sam_munition_exhaust_beam_01_emit.bp',

    # Hit Effects
    FxUnitHitScale = 0.5,
    FxImpactUnit = {},
    FxLandHitScale = 0.5,
    FxImpactLand = EffectTemplate.CMissileHit01,
    FxImpactUnderWater = {},
}

#------------------------------------------------------------------------
#  DISINTEGRATOR LASER PROJECILE
#------------------------------------------------------------------------
CDisintegratorLaserProjectile = Class(MultiPolyTrailProjectile) {
    PolyTrails = {
        '/effects/emitters/disintegrator_polytrail_04_emit.bp',
        '/effects/emitters/disintegrator_polytrail_05_emit.bp',
        '/effects/emitters/default_polytrail_03_emit.bp',
    },
    PolyTrailOffset = {0,0,0},
    FxTrails = EffectTemplate.CDisintegratorFxTrails01,

    # Hit Effects
    FxImpactUnit = EffectTemplate.CDisintegratorHitUnit01,
    FxImpactAirUnit = EffectTemplate.CDisintegratorHitAirUnit01,
    FxImpactProp = EffectTemplate.CDisintegratorHitUnit01,
    FxImpactLand = EffectTemplate.CDisintegratorHitLand01,
    FxImpactUnderWater = {},
}

#	adjusments for URA0104 to tone down effect
CDisintegratorLaserProjectile02 = Class(MultiPolyTrailProjectile) {
    PolyTrails = {
        '/effects/emitters/disintegrator_polytrail_04_emit.bp',
        '/effects/emitters/disintegrator_polytrail_05_emit.bp',
        '/effects/emitters/default_polytrail_03_emit.bp',
    },
    PolyTrailOffset = {0,0,0},

    # Hit Effects
    FxImpactUnit = EffectTemplate.CDisintegratorHitUnit01,
    FxImpactAirUnit = EffectTemplate.CDisintegratorHitAirUnit01,
    FxImpactProp = EffectTemplate.CDisintegratorHitUnit01,
    FxImpactLand = EffectTemplate.CDisintegratorHitLand01,
    FxImpactUnderWater = {},
}

#------------------------------------------------------------------------
#  CYBRAN ELECTRON BOLTER PROJECILES
#------------------------------------------------------------------------
CElectronBolterProjectile = Class(MultiPolyTrailProjectile) {

    PolyTrails = {
        '/effects/emitters/electron_bolter_trail_02_emit.bp',
        '/effects/emitters/default_polytrail_01_emit.bp',
    },
    PolyTrailOffset = {0,0},
    FxTrails = {'/effects/emitters/electron_bolter_munition_01_emit.bp',},

    # Hit Effects
    FxImpactUnit = EffectTemplate.CElectronBolterHitUnit01,
    FxImpactProp = EffectTemplate.CElectronBolterHitUnit01,
    FxImpactLand = EffectTemplate.CElectronBolterHitLand01,
}

CHeavyElectronBolterProjectile = Class(MultiPolyTrailProjectile) {

    PolyTrails = {
        '/effects/emitters/electron_bolter_trail_01_emit.bp',
        '/effects/emitters/default_polytrail_05_emit.bp',
    },
    PolyTrailOffset = {0,0},
    FxTrails = {'/effects/emitters/electron_bolter_munition_02_emit.bp',},

    # Hit Effects
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

#------------------------------------------------------------------------
#  TERRAN SUB-LAUNCHED CRUISE MISSILE PROJECTILES
#------------------------------------------------------------------------
CEMPFluxWarheadProjectile = Class(NukeProjectile, SingleBeamProjectile) {
    BeamName = '/effects/emitters/missile_exhaust_fire_beam_01_emit.bp',
    FxInitialAtEntityEmitter = {},
    FxUnderWaterTrail = {'/effects/emitters/missile_cruise_munition_underwater_trail_01_emit.bp',},
    FxOnEntityEmitter = {},
    FxExitWaterEmitter = EffectTemplate.DefaultProjectileWaterImpact,
    FxSplashScale = 0.65,
    ExitWaterTicks = 9,
    FxTrailOffset = -0.5,

    # LAUNCH TRAILS
    FxLaunchTrails = {},

    # TRAILS
    FxTrails = {'/effects/emitters/missile_cruise_munition_trail_01_emit.bp',},

    # Hit Effects
    FxImpactUnit = {},
    FxImpactLand = {},
    FxImpactUnderWater = {},
}

#------------------------------------------------------------------------
#  CYBRAN FLAME THROWER PROJECTILES
#------------------------------------------------------------------------
CFlameThrowerProjectile = Class(EmitterProjectile) {
    FxTrails = {'/effects/emitters/flamethrower_02_emit.bp'},
    FxTrailScale = 1,
    FxTrailOffset = 0,
    FxImpactUnderWater = {},
}

#------------------------------------------------------------------------
#  CYBRAN MOLECULAR RESONANCE SHELL PROJECTILE
#------------------------------------------------------------------------
CIFMolecularResonanceShell = Class(SinglePolyTrailProjectile) {

    PolyTrail = '/effects/emitters/default_polytrail_01_emit.bp',

    # Hit Effects
    FxImpactUnit = EffectTemplate.CMolecularResonanceHitUnit01,
    FxImpactProp = EffectTemplate.CMolecularResonanceHitUnit01,
    FxImpactLand = EffectTemplate.CMolecularResonanceHitUnit01,
    FxImpactUnderWater = {},
    DestroyOnImpact = false,

    OnCreate = function(self)
        SinglePolyTrailProjectile.OnCreate(self)
        self.Impacted = false
    end,

    DelayedDestroyThread = function(self)
        WaitSeconds(0.3)
        self.CreateImpactEffects(self, self.Army, self.FxImpactUnit, self.FxUnitHitScale)
        self:Destroy()
    end,

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

#------------------------------------------------------------------------
#  IRIDIUM ROCKET PROJECTILES
#------------------------------------------------------------------------
CIridiumRocketProjectile = Class(SingleCompositeEmitterProjectile) {
    FxTrails = {},
    PolyTrail = '/effects/emitters/cybran_iridium_missile_polytrail_01_emit.bp',
    BeamName = '/effects/emitters/rocket_iridium_exhaust_beam_01_emit.bp',
    FxImpactUnit = EffectTemplate.CMissileHit02,
    FxImpactProp = EffectTemplate.CMissileHit02,
    FxImpactLand = EffectTemplate.CMissileHit02,
    FxImpactUnderWater = {},
}

#------------------------------------------------------------------------
#  CORSAIR MISSILE PROJECTILES
#------------------------------------------------------------------------
CCorsairRocketProjectile = Class(SingleCompositeEmitterProjectile) {
    FxTrails = {},
    PolyTrail = EffectTemplate.CCorsairMissilePolyTrail01,
    BeamName = '/effects/emitters/rocket_iridium_exhaust_beam_01_emit.bp',
    FxImpactUnit = EffectTemplate.CCorsairMissileUnitHit01,
    FxImpactProp = EffectTemplate.CCorsairMissileHit01,
    FxImpactLand = EffectTemplate.CCorsairMissileLandHit01,
    FxImpactUnderWater = {},
    
    OnImpact = function(self, targetType, targetEntity)
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
            local rotation = RandomFloat(0,2*math.pi)
            local radius = self.DamageData.DamageRadius
            local pos = self:GetPosition()
            local army = self.Army

            DamageArea(self, pos, radius, 1, 'Force', true)
            DamageArea(self, pos, radius, 1, 'Force', true)
            CreateDecal(pos, rotation, 'scorch_001_albedo', '', 'Albedo', radius, radius, 150, 50, army)
        end
        
        SinglePolyTrailProjectile.OnImpact(self, targetType, targetEntity)
    end,
}

#------------------------------------------------------------------------
#  CYBRAN LASER PROJECILES
#------------------------------------------------------------------------
CLaserLaserProjectile = Class(MultiPolyTrailProjectile) {
    PolyTrails = {
        '/effects/emitters/cybran_laser_trail_01_emit.bp',
        '/effects/emitters/default_polytrail_02_emit.bp',
    },
    PolyTrailOffset = {0,0},

    # Hit Effects
    FxImpactUnit = EffectTemplate.CLaserHitUnit01,
    FxImpactProp = EffectTemplate.CLaserHitUnit01,
    FxImpactLand = EffectTemplate.CLaserHitLand01,
    FxImpactUnderWater = {},
}

CHeavyLaserProjectile = Class(MultiPolyTrailProjectile) {
    PolyTrails = {
        '/effects/emitters/cybran_laser_trail_02_emit.bp',
        '/effects/emitters/default_polytrail_03_emit.bp',
    },
    PolyTrailOffset = {0,0},

    # Hit Effects
    FxImpactUnit = EffectTemplate.CLaserHitUnit01,
    FxImpactProp = EffectTemplate.CLaserHitUnit01,
    FxImpactLand = EffectTemplate.CLaserHitLand01,
    FxImpactUnderWater = {},
}

CHeavyLaserProjectile2 = Class(MultiPolyTrailProjectile) {
    PolyTrails = {
        '/effects/emitters/hrailgunsd_polytrail_01_emit.bp',
                '/effects/emitters/default_polytrail_02_emit.bp',
    },
    PolyTrailOffset = {0,0},

    # Hit Effects
    FxUnitHitScale = 0.15,
    FxLandHitScale = 0.15,
    FxImpactUnit = EffectTemplate.CBeamHitUnit01,
    FxImpactProp = EffectTemplate.CBeamHitUnit01,
    FxImpactLand = EffectTemplate.CBeamHitLand01,
    FxImpactUnderWater = {},
}

#------------------------------------------------------------------------
#  CYBRAN MOLECULAR CANNON PROJECTILE
#------------------------------------------------------------------------
CMolecularCannonProjectile = Class(SinglePolyTrailProjectile) {
    FxImpactTrajectoryAligned = false,
    PolyTrail = '/effects/emitters/default_polytrail_03_emit.bp',
    FxTrails = EffectTemplate.CMolecularCannon01,

    # Hit Effects
    FxImpactUnit = EffectTemplate.CMolecularRipperHit01,
    FxImpactProp = EffectTemplate.CMolecularRipperHit01,
    FxImpactLand = EffectTemplate.CMolecularRipperHit01,
}

#------------------------------------------------------------------------
#  CYBRAN AA MISSILE PROJECILES - Air Targets
#------------------------------------------------------------------------
CMissileAAProjectile = Class(SingleCompositeEmitterProjectile) {
    # Emitter Values
    FxInitial = {},
    TrailDelay = 1,
    FxTrails = {'/effects/emitters/missile_sam_munition_trail_01_emit.bp',},
    FxTrailOffset = 0.5,

    BeamName = '/effects/emitters/missile_sam_munition_exhaust_beam_01_emit.bp',

    # Hit Effects
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

#------------------------------------------------------------------------
#  NEUTRON CLUSTER BOMB PROJECTILES
#------------------------------------------------------------------------
CNeutronClusterBombChildProjectile = Class(SinglePolyTrailProjectile) {
    FxTrails = {},
    PolyTrail = '/effects/emitters/default_polytrail_05_emit.bp',

    # Hit Effects
    FxImpactUnit = EffectTemplate.CNeutronClusterBombHitUnit01,
    FxImpactProp = EffectTemplate.CNeutronClusterBombHitUnit01,
    FxImpactLand = EffectTemplate.CNeutronClusterBombHitLand01,
    FxImpactWater = EffectTemplate.CNeutronClusterBombHitWater01,
    FxImpactUnderWater = {},

    # No damage dealt by this child.
    DoDamage = function(self, instigator, damageData, targetEntity)
    end,
}

CNeutronClusterBombProjectile = Class(SinglePolyTrailProjectile) {
    FxTrails = {},
    PolyTrail = '/effects/emitters/default_polytrail_03_emit.bp',

    # Hit Effects
    FxImpactUnit = {},
    FxImpactLand = {},
    FxImpactUnderWater = {},

    ChildProjectile = '/projectiles/CIFNeutronClusterBomb02/CIFNeutronClusterBomb02_proj.bp',

    OnCreate = function(self)
        SinglePolyTrailProjectile.OnCreate(self)
        self.Impacted = false
    end,

    # -------------------------------------------------------------------------
    # Over-ride the way damage is dealt to allow custom damage to be dealt.
    # Spec 9/21/05 states that possible instakill functionality could be dealt
    # to unit, dependent on units current armor level.
    # ### Spec pending revision ### Update when finalized.
    # ---------------------------------------------------------------------------
    DoDamage = function(self, instigator, damageData, targetEntity)
        SinglePolyTrailProjectile.DoDamage(self, instigator, damageData, targetEntity)
    end,

    # ---------------------------------------------------------------------------
    # Note: Damage is done once in AOE by main projectile. Secondary projectiles
    # are just visual.
    # ---------------------------------------------------------------------------
    OnImpact = function(self, targetType, targetEntity)
        if self.Impacted == false and targetType ~= 'Air' then
            self.Impacted = true
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

    # Overiding Destruction
    OnImpactDestroy = function(self, targetType, targetEntity)
        self:ForkThread(self.DelayedDestroyThread)
    end,

    DelayedDestroyThread = function(self)
        WaitSeconds(0.5)
        self:Destroy()
    end,
}

#------------------------------------------------------------------------
#  CYBRAN MACHINE GUN SHELLS
#------------------------------------------------------------------------
CParticleCannonProjectile = Class(SingleBeamProjectile) {
    BeamName = '/effects/emitters/laserturret_munition_beam_01_emit.bp',

# Hit Effects
    FxImpactUnit = EffectTemplate.CParticleCannonHitUnit01,
    FxImpactProp = EffectTemplate.CParticleCannonHitUnit01,
    FxImpactLand = EffectTemplate.CParticleCannonHitLand01,
    FxImpactUnderWater = {},
}

#------------------------------------------------------------------------
#  CYBRAN RAIL GUN PROJECTILES
#------------------------------------------------------------------------
CRailGunProjectile = Class(EmitterProjectile) {
    FxTrails = {'/effects/emitters/railgun_munition_trail_02_emit.bp',
                '/effects/emitters/railgun_munition_trail_01_emit.bp'},
    FxTrailScale = 0,
    FxTrailOffset = 0,
    FxImpactUnderWater = {},
}

#------------------------------------------------------------------------
#  CYBRAN ROCKET PROJECILES
#------------------------------------------------------------------------
CRocketProjectile = Class(SingleBeamProjectile) {
    # Emitter Values
    BeamName = '/effects/emitters/rocket_iridium_exhaust_beam_01_emit.bp',

    # Hit Effects
    FxImpactUnit = EffectTemplate.CMissileHit01,
    FxImpactProp = EffectTemplate.CMissileHit01,
    FxImpactLand = EffectTemplate.CMissileHit01,
    FxImpactUnderWater = {},
}

CLOATacticalMissileProjectile = Class(SingleBeamProjectile) {

    BeamName = '/effects/emitters/missile_loa_munition_exhaust_beam_01_emit.bp',
    FxTrails = {'/effects/emitters/missile_cruise_munition_trail_01_emit.bp',},
    FxTrailOffset = -0.5,
    FxExitWaterEmitter = EffectTemplate.TIFCruiseMissileLaunchExitWater,

    # Hit Effects
    FxImpactUnit = EffectTemplate.CMissileLOAHit01,
    FxImpactLand = EffectTemplate.CMissileLOAHit01,
    FxImpactProp = EffectTemplate.CMissileLOAHit01,
    FxImpactNone = EffectTemplate.CMissileLOAHit01,
    FxImpactUnderWater = {},

    CreateImpactEffects = function(self, army, EffectTable, EffectScale)
        local emit = nil
        for k, v in EffectTable do
            emit = CreateEmitterAtEntity(self,army,v)
            if emit and EffectScale ~= 1 then
                emit:ScaleEmitter(EffectScale or 1)
            end
        end
    end,

    OnExitWater = function(self)
        EmitterProjectile.OnExitWater(self)
        for k, v in self.FxExitWaterEmitter do
            CreateEmitterAtBone(self, -2, self.Army, v)
        end
    end,
}

CLOATacticalChildMissileProjectile = Class(SingleBeamProjectile) {
    BeamName = '/effects/emitters/missile_loa_munition_exhaust_beam_02_emit.bp',
    FxTrails = {'/effects/emitters/missile_cruise_munition_trail_03_emit.bp',},
    FxTrailOffset = -0.5,
    FxExitWaterEmitter = EffectTemplate.TIFCruiseMissileLaunchExitWater,

    # Hit Effects
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

    OnCreate = function(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)
        SingleBeamProjectile.OnCreate(self)
    end,

    OnImpact = function(self, targetType, targetEntity)
        CreateLightParticle(self, -1, self.Army, 1, 7, 'glow_03', 'ramp_fire_11')
        SingleBeamProjectile.OnImpact(self, targetType, targetEntity)
    end,

    CreateImpactEffects = function(self, army, EffectTable, EffectScale)
        local emit = nil
        for k, v in EffectTable do
            emit = CreateEmitterAtEntity(self, army, v)
            if emit and EffectScale ~= 1 then
                emit:ScaleEmitter(EffectScale or 1)
            end
        end
    end,

    OnExitWater = function(self)
        EmitterProjectile.OnExitWater(self)
        for k, v in self.FxExitWaterEmitter do
            CreateEmitterAtBone(self, -2, self.Army, v)
        end
    end,
}

#------------------------------------------------------------------------
#  CYBRAN AUTOCANNON PROJECILES
#------------------------------------------------------------------------
CShellAAAutoCannonProjectile = Class(MultiPolyTrailProjectile) {
    PolyTrails = {
        '/effects/emitters/auto_cannon_trail_01_emit.bp',
        '/effects/emitters/default_polytrail_03_emit.bp',
    },
    PolyTrailOffset = {0,0},

    # Hit Effects
    FxImpactUnit = {'/effects/emitters/auto_cannon_hit_flash_01_emit.bp', },
    FxImpactProp ={'/effects/emitters/auto_cannon_hit_flash_01_emit.bp', },
    FxImpactAirUnit = {'/effects/emitters/auto_cannon_hit_flash_01_emit.bp', },
    FxImpactLand = {},
    FxImpactWater = {},
    FxImpactUnderWater = {},
}

#------------------------------------------------------------------------
#  CYBRAN RIOT PROJECILES
#------------------------------------------------------------------------
CShellRiotProjectile = Class(SingleBeamProjectile) {
    BeamName = '/effects/emitters/riotgun_munition_beam_01_emit.bp',

    # Hit Effects
    FxImpactUnit = {'/effects/emitters/destruction_explosion_sparks_01_emit.bp',},
    FxImpactProp = {'/effects/emitters/destruction_explosion_sparks_01_emit.bp',},
    FxLandHitScale = 3,
    FxImpactLand = {'/effects/emitters/destruction_land_hit_puff_01_emit.bp',},
    FxImpactUnderWater = {},
}

#------------------------------------------------------------------------
#  CYBRAN ABOVE WATER LAUNCHED TORPEDO
#------------------------------------------------------------------------
CTorpedoShipProjectile = Class(OnWaterEntryEmitterProjectile) {
    FxSplashScale = 0.5,
    FxTrails = {'/effects/emitters/torpedo_munition_trail_01_emit.bp',},
    FxTrailScale = 1.25,
    FxTrailOffset = 0.2,
    FxEnterWater= { '/effects/emitters/water_splash_ripples_ring_01_emit.bp',
                    '/effects/emitters/water_splash_plume_01_emit.bp',},

# Hit Effects
    FxUnitHitScale = 1.25,
    FxImpactUnit = EffectTemplate.CTorpedoUnitHit01,
    FxImpactProp = EffectTemplate.CTorpedoUnitHit01,
    FxImpactUnderWater = EffectTemplate.CTorpedoUnitHit01,
    FxImpactLand = {},
    FxImpactNone = {},

    OnCreate = function(self, inWater)
        OnWaterEntryEmitterProjectile.OnCreate(self, inWater)
        # if we are starting in the water then immediately switch to tracking in water
        if inWater == true then
            self:TrackTarget(true):StayUnderwater(true)
            self:OnEnterWater(self)
        end
    end,


    OnEnterWater = function(self)
        OnWaterEntryEmitterProjectile.OnEnterWater(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)
    end,

}

#------------------------------------------------------------------------
#  CYBRAN SUB LAUNCHED TORPEDO
#------------------------------------------------------------------------
CTorpedoSubProjectile = Class(EmitterProjectile) {
    FxTrails = {'/effects/emitters/torpedo_underwater_wake_02_emit.bp',},

    # Hit Effects
    FxUnitHitScale = 1.25,
    FxImpactUnit = EffectTemplate.CTorpedoUnitHit01,
    FxImpactProp = EffectTemplate.CTorpedoUnitHit01,
    FxImpactUnderWater = EffectTemplate.CTorpedoUnitHit01,
    FxImpactLand = EffectTemplate.CTorpedoUnitHit01,
    FxLandHitScale = 0.25,
    FxNoneHitScale = 1,
    FxImpactNone = {},
    OnCreate = function(self, inWater)
        self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)
        EmitterProjectile.OnCreate(self, inWater)
    end,
}

#------------------------------------------------------------------------
#  Cybran DEPTH CHARGE PROJECTILES
#------------------------------------------------------------------------
CDepthChargeProjectile = Class(OnWaterEntryEmitterProjectile) {
    FxInitial = {},
    FxTrails = {
        '/effects/emitters/anti_torpedo_flare_01_emit.bp',
        '/effects/emitters/anti_torpedo_flare_02_emit.bp',
    },

    # Hit Effects
    FxImpactLand = {},
    FxImpactUnit = EffectTemplate.CAntiTorpedoHit01,
    FxImpactProp = EffectTemplate.CAntiTorpedoHit01,
    FxImpactUnderWater = EffectTemplate.CAntiTorpedoHit01,
    FxImpactProjectile = EffectTemplate.CAntiTorpedoHit01,
    FxImpactNone = EffectTemplate.CAntiTorpedoHit01,
    FxOnKilled = EffectTemplate.CAntiTorpedoHit01,
    FxEnterWater= EffectTemplate.WaterSplash01,

    OnCreate = function(self, inWater)
        OnWaterEntryEmitterProjectile.OnCreate(self)
        if inWater then
            for i in self.FxTrails do
                CreateEmitterOnEntity(self, self.Army, self.FxTrails[i]):ScaleEmitter(self.FxTrailScale):OffsetEmitter(0, 0, self.FxTrailOffset)
            end
        end

        self:TrackTarget(false)
    end,

    OnEnterWater = function(self)
        OnWaterEntryEmitterProjectile.OnEnterWater(self)

        for k, v in self.FxEnterWater do --splash
            CreateEmitterAtEntity(self, self.Army, v)
        end

        self:TrackTarget(false)
        self:StayUnderwater(true)
        self:SetTurnRate(0)
        self:SetMaxSpeed(1)
        self:SetVelocity(0, -0.25, 0)
        self:SetVelocity(0.25)
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

#------------------------------------------------------------------------
#
#  SC1 EXPANSION PROJECTILES
#
#------------------------------------------------------------------------

CHeavyDisintegratorPulseLaser = Class(MultiPolyTrailProjectile) {
    PolyTrails = {
        '/effects/emitters/disintegrator_polytrail_02_emit.bp',
        '/effects/emitters/disintegrator_polytrail_03_emit.bp',
        '/effects/emitters/default_polytrail_03_emit.bp',
    },
    PolyTrailOffset = {0,0,0},

    # Hit Effects
    FxImpactUnit = EffectTemplate.CHvyDisintegratorHitUnit01,
    FxImpactProp = EffectTemplate.CHvyDisintegratorHitUnit01,
    FxImpactLand = EffectTemplate.CHvyDisintegratorHitLand01,
    FxImpactUnderWater = {},
    FxTrails = {},
    FxTrailOffset = 0,
}


CKrilTorpedo = Class(OnWaterEntryEmitterProjectile) {
}

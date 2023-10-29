------------------------------------------------------------
--  File     :  /data/lua/cybranprojectiles.lua
--  Author(s): John Comes, Gordon Duclos
--  Summary  :
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------

--  CYBRAN PROJECILES SCRIPTS
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

local TacticalMissileComponent = import('/lua/sim/DefaultProjectiles.lua').TacticalMissileComponent
local SplitComponent = import('/lua/sim/projectiles/components/SplitComponent.lua').SplitComponent
local DebrisComponent = import('/lua/sim/projectiles/components/DebrisComponent.lua').DebrisComponent

---  CYBRAN BRACKMAN "HACK PEG-POD" PROJECTILE
---@class CDFBrackmanHackPegProjectile01 : MultiPolyTrailProjectile
CDFBrackmanHackPegProjectile01 = ClassProjectile(MultiPolyTrailProjectile) {
    FxImpactTrajectoryAligned = false,
    PolyTrails = EffectTemplate.CBrackmanCrabPegPodTrails,
    PolyTrailOffset = { 0, 0 },
    FxTrailOffset = 0,
}

---  CYBRAN BRACKMAN "HACK PEG" PROJECTILES
---@class CDFBrackmanHackPegProjectile02 : MultiPolyTrailProjectile
CDFBrackmanHackPegProjectile02 = ClassProjectile(MultiPolyTrailProjectile) {
    FxImpactTrajectoryAligned = false,
    PolyTrails = EffectTemplate.CBrackmanCrabPegTrails,
    PolyTrailOffset = { 0, 0 },
    FxImpactLand = EffectTemplate.CBrackmanCrabPegHit01,
    FxTrailOffset = 0,
}

--- CYBRAN PROTON PROJECTILES
--- T3 strategic bomber
---@class CIFProtonBombProjectile : NullShell
CIFProtonBombProjectile = ClassProjectile(NullShell) {
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
        local blanketVelocity = 6.25
        for i = 0, (blanketSides-1) do
            local blanketX = math.sin(i*blanketAngle)
            local blanketZ = math.cos(i*blanketAngle)
            self:CreateProjectile('/effects/entities/EffectProtonAmbient01/EffectProtonAmbient01_proj.bp', blanketX, 0.5, blanketZ, blanketX, 0, blanketZ):SetVelocity(blanketVelocity):SetAcceleration(-0.3)
        end
        NullShell.OnImpact(self, targetType, targetEntity)
    end,
}

---  CYBRAN PROTON PROJECTILES
---@class CDFProtonCannonProjectile : MultiPolyTrailProjectile
CDFProtonCannonProjectile = ClassProjectile(MultiPolyTrailProjectile) {
    PolyTrails = {
        EffectTemplate.CProtonCannonPolyTrail,
        '/effects/emitters/default_polytrail_01_emit.bp',
    },
    PolyTrailOffset = { 0, 0 },
    FxTrails = EffectTemplate.CProtonCannonFXTrail01,
    FxImpactUnit = EffectTemplate.CProtonCannonHit01,
    FxImpactProp = EffectTemplate.CProtonCannonHit01,
    FxImpactLand = EffectTemplate.CProtonCannonHit01,
    FxImpactWater = EffectTemplate.CProtonCannonHitWater01,
    FxImpactWaterScale = 0.75,
    FxTrailOffset = 0,
}

--- CYBRAN PROTON PROJECTILES
--- XRL0403 experimental crab heavy proton cannon
---@class CDFHvyProtonCannonProjectile : MultiPolyTrailProjectile
CDFHvyProtonCannonProjectile = ClassProjectile(MultiPolyTrailProjectile) {
    PolyTrails = {
        EffectTemplate.CHvyProtonCannonPolyTrail,
        '/effects/emitters/default_polytrail_01_emit.bp',
    },
    PolyTrailOffset = { 0, 0 },
    FxTrails = EffectTemplate.CHvyProtonCannonFXTrail01,
    FxImpactUnit = EffectTemplate.CHvyProtonCannonHitUnit,
    FxImpactProp = EffectTemplate.CHvyProtonCannonHitUnit,
    FxImpactLand = EffectTemplate.CHvyProtonCannonHitLand,
    FxImpactUnderWater = EffectTemplate.CHvyProtonCannonHit01,
    FxImpactWater = EffectTemplate.CHvyProtonCannonHit01,
    FxTrailOffset = 0,
}

---  CYBRAN DISSIDENT PROJECTILE
---@class CAADissidentProjectile : SinglePolyTrailProjectile
CAADissidentProjectile = ClassProjectile(SinglePolyTrailProjectile) {
    PolyTrail = '/effects/emitters/electron_bolter_trail_01_emit.bp',
    FxTrails = {'/effects/emitters/electron_bolter_munition_01_emit.bp',},
    FxImpactUnit = EffectTemplate.TMissileHit01,
    FxImpactProp = EffectTemplate.TMissileHit01,
    FxImpactLand = EffectTemplate.TMissileHit01,
    FxImpactProjectile = EffectTemplate.TMissileHit01,
}

---  ELECTRON BURST CLOUD PROJECILE
---@class CAAElectronBurstCloudProjectile : SinglePolyTrailProjectile
CAAElectronBurstCloudProjectile = ClassProjectile(SinglePolyTrailProjectile) {
    PolyTrail = '/effects/emitters/default_polytrail_02_emit.bp',
    FxImpactAirUnit = EffectTemplate.CElectronBurstCloud01,
    FxImpactNone = EffectTemplate.CElectronBurstCloud01,
}

---  NANITE MISSILE PROJECTILE
---@class CAAMissileNaniteProjectile : SingleCompositeEmitterProjectile
CAAMissileNaniteProjectile = ClassProjectile(SingleCompositeEmitterProjectile) {
    FxTrailOffset = -0.05,
    PolyTrail =  EffectTemplate.CNanoDartPolyTrail01,
    BeamName = '/effects/emitters/missile_nanite_exhaust_beam_01_emit.bp',
    FxUnitHitScale = 0.5,
    FxImpactAirUnit = EffectTemplate.CNanoDartUnitHit01,
    FxImpactNone = EffectTemplate.CNanoDartUnitHit01,
    FxImpactUnit = EffectTemplate.CNanoDartUnitHit01,
    FxImpactProp = EffectTemplate.CNanoDartUnitHit01,
    FxLandHitScale = 0.5,
    FxImpactLand = EffectTemplate.CMissileHit01,
}

---  NANITE MISSILE PROJECTILE
---@class CAAMissileNaniteProjectile03 : CAAMissileNaniteProjectile
CAAMissileNaniteProjectile03 = ClassProjectile(CAAMissileNaniteProjectile) {}

---  NANODART PROJECILE
---@class CAANanoDartProjectile : SinglePolyTrailProjectile
CAANanoDartProjectile = ClassProjectile(SinglePolyTrailProjectile) {
    FxImpactTrajectoryAligned = false,
    PolyTrail= EffectTemplate.CNanoDartPolyTrail01,
    FxImpactAirUnit = EffectTemplate.CNanoDartUnitHit01,
    FxImpactUnit = EffectTemplate.CNanoDartUnitHit01,
    FxImpactLand = EffectTemplate.CNanoDartLandHit01,
}

---  NANODART PROJECILE
---@class CAANanoDartProjectile02 : CAANanoDartProjectile
CAANanoDartProjectile02 = ClassProjectile(CAANanoDartProjectile) {
    PolyTrail= EffectTemplate.CNanoDartPolyTrail02,
}

---  NANODART PROJECILE
--- adjustment to make the effects for URL0104 cheaper
---@class CAANanoDartProjectile03 : CAANanoDartProjectile
CAANanoDartProjectile03 = ClassProjectile(CAANanoDartProjectile) {
    FxImpactAirUnit = EffectTemplate.CNanoDartUnitHit02,
    FxImpactUnit = EffectTemplate.CNanoDartUnitHit02,
    FxImpactLand = EffectTemplate.CNanoDartLandHit02,
}

---  CYBRAN ARTILLERY PROJECILES
---@class CArtilleryProjectile : EmitterProjectile
CArtilleryProjectile = ClassProjectile(EmitterProjectile) {
    FxTrails = {'/effects/emitters/mortar_munition_03_emit.bp',},
    FxImpactUnit = EffectTemplate.CNanoDartUnitHit01,
    FxImpactProp = EffectTemplate.CArtilleryHit01,
    FxImpactLand = EffectTemplate.CArtilleryHit01,
}

---  CYBRAN ARTILLERY PROJECILES
---@class CArtilleryProtonProjectile : SinglePolyTrailProjectile
CArtilleryProtonProjectile = ClassProjectile(SinglePolyTrailProjectile) {
    FxImpactTrajectoryAligned = false,
    PolyTrail = '/effects/emitters/default_polytrail_01_emit.bp',
    FxImpactUnit = EffectTemplate.CProtonArtilleryHit01,
    FxImpactProp = EffectTemplate.CProtonArtilleryHit01,
    FxImpactLand = EffectTemplate.CProtonArtilleryHit01,

    ---@param self CArtilleryProtonProjectile
    ---@param targetType string
    ---@param targetEntity Unit
    OnImpact = function(self, targetType, targetEntity)
        EmitterProjectile.OnImpact(self, targetType, targetEntity)
        CreateLightParticle( self, -1, self.Army, 7, 12, 'glow_03', 'ramp_red_06' )
        CreateLightParticle( self, -1, self.Army, 7, 22, 'glow_03', 'ramp_antimatter_02' )
    end,
}

---  CYBRAN BEAM PROJECILES
---@class CBeamProjectile : NullShell
CBeamProjectile = ClassProjectile(NullShell) {
    FxUnitHitScale = 0.5,
    FxImpactUnit = EffectTemplate.CBeamHitUnit01,
    FxImpactProp = EffectTemplate.CBeamHitUnit01,
    FxImpactLand = EffectTemplate.CBeamHitLand01,
}

---  CYBRAN BOMBs
---@class CBombProjectile : EmitterProjectile
CBombProjectile = ClassProjectile(EmitterProjectile) {
    FxTrails = {'/effects/emitters/bomb_munition_plasma_aeon_01_emit.bp'},
    FxImpactUnit = EffectTemplate.CBombHit01,
    FxImpactProp = EffectTemplate.CBombHit01,
    FxImpactLand = EffectTemplate.CBombHit01,
}

---  CYBRAN SHIP PROJECILES
---@class CCannonSeaProjectile : SingleBeamProjectile
CCannonSeaProjectile = ClassProjectile(SingleBeamProjectile) {
    BeamName = '/effects/emitters/cannon_munition_ship_cybran_beam_01_emit.bp',
}

---  CYBRAN TANK CANNON PROJECILES
---@class CCannonTankProjectile : SingleBeamProjectile
CCannonTankProjectile = ClassProjectile(SingleBeamProjectile) {
    BeamName = '/effects/emitters/cannon_munition_ship_cybran_beam_01_emit.bp',
}

---  CYBRAN TRACKER PROJECILES
---@class CDFTrackerProjectile : SingleCompositeEmitterProjectile
CDFTrackerProjectile = ClassProjectile(SingleCompositeEmitterProjectile) {
    TrailDelay = 1,
    FxTrails = {'/effects/emitters/missile_sam_munition_trail_01_emit.bp',},
    FxTrailOffset = 0.5,
    BeamName = '/effects/emitters/missile_sam_munition_exhaust_beam_01_emit.bp',
    FxUnitHitScale = 0.5,
    FxLandHitScale = 0.5,
    FxImpactLand = EffectTemplate.CMissileHit01,
}

---  DISINTEGRATOR LASER PROJECILE
--- loyalist & wailers
---@class CDisintegratorLaserProjectile : MultiPolyTrailProjectile
CDisintegratorLaserProjectile = ClassProjectile(MultiPolyTrailProjectile) {
    PolyTrails = {
        '/effects/emitters/disintegrator_polytrail_04_emit.bp',
        '/effects/emitters/disintegrator_polytrail_05_emit.bp',
        '/effects/emitters/default_polytrail_03_emit.bp',
    },
    PolyTrailOffset = { 0, 0, 0 },
    FxTrails = EffectTemplate.CDisintegratorFxTrails01,
    FxImpactUnit = EffectTemplate.CDisintegratorHitUnit01,
    FxImpactAirUnit = EffectTemplate.CDisintegratorHitAirUnit01,
    FxImpactProp = EffectTemplate.CDisintegratorHitUnit01,
    FxImpactLand = EffectTemplate.CDisintegratorHitLand01,
}

---  DISINTEGRATOR LASER PROJECILE
--- adjusments for URA0104 to tone down effect
---@class CDisintegratorLaserProjectile02 : MultiPolyTrailProjectile
CDisintegratorLaserProjectile02 = ClassProjectile(MultiPolyTrailProjectile) {
    PolyTrails = {
        '/effects/emitters/disintegrator_polytrail_04_emit.bp',
        '/effects/emitters/disintegrator_polytrail_05_emit.bp',
        '/effects/emitters/default_polytrail_03_emit.bp',
    },
    PolyTrailOffset = { 0, 0, 0 },
    FxImpactUnit = EffectTemplate.CDisintegratorHitUnit01,
    FxImpactAirUnit = EffectTemplate.CDisintegratorHitAirUnit01,
    FxImpactProp = EffectTemplate.CDisintegratorHitUnit01,
    FxImpactLand = EffectTemplate.CDisintegratorHitLand01,
}

---  CYBRAN ELECTRON BOLTER PROJECILES
--- loya, wagner, monkeylord & soul ripper
---@class CElectronBolterProjectile : MultiPolyTrailProjectile
CElectronBolterProjectile = ClassProjectile(MultiPolyTrailProjectile) {
    PolyTrails = {
        '/effects/emitters/electron_bolter_trail_02_emit.bp',
        '/effects/emitters/default_polytrail_01_emit.bp',
    },
    PolyTrailOffset = { 0, 0 },
    FxTrails = {'/effects/emitters/electron_bolter_munition_01_emit.bp',},
    FxImpactUnit = EffectTemplate.CElectronBolterHitUnit01,
    FxImpactProp = EffectTemplate.CElectronBolterHitUnit01,
    FxImpactLand = EffectTemplate.CElectronBolterHitLand01,
}

--- SoulRipper
---@class CHeavyElectronBolterProjectile : MultiPolyTrailProjectile
CHeavyElectronBolterProjectile = ClassProjectile(MultiPolyTrailProjectile) {
    PolyTrails = {
        '/effects/emitters/electron_bolter_trail_01_emit.bp',
        '/effects/emitters/default_polytrail_05_emit.bp',
    },
    PolyTrailOffset = { 0, 0 },
    FxTrails = {'/effects/emitters/electron_bolter_munition_02_emit.bp',},
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

---  TERRAN SUB-LAUNCHED CRUISE MISSILE PROJECTILES
---@class CEMPFluxWarheadProjectile : NukeProjectile
CEMPFluxWarheadProjectile = ClassProjectile(NukeProjectile, SingleBeamProjectile) {
    BeamName = '/effects/emitters/missile_exhaust_fire_beam_01_emit.bp',
    FxUnderWaterTrail = {'/effects/emitters/missile_cruise_munition_underwater_trail_01_emit.bp'},
    FxExitWaterEmitter = EffectTemplate.DefaultProjectileWaterImpact,
    FxSplashScale = 0.65,
    ExitWaterTicks = 9,
    FxTrailOffset = -0.5,
    FxTrails = {'/effects/emitters/missile_cruise_munition_trail_01_emit.bp'},
}

---  CYBRAN FLAME THROWER PROJECTILES
---@class CFlameThrowerProjectile : EmitterProjectile
CFlameThrowerProjectile = ClassProjectile(EmitterProjectile) {
    FxTrails = {'/effects/emitters/flamethrower_02_emit.bp'},
    FxTrailScale = 1,
    FxTrailOffset = 0,
}

---  CYBRAN MOLECULAR RESONANCE SHELL PROJECTILE
---@class CIFMolecularResonanceShell : SinglePolyTrailProjectile
CIFMolecularResonanceShell = ClassProjectile(SinglePolyTrailProjectile) {
    PolyTrail = '/effects/emitters/default_polytrail_01_emit.bp',
    FxImpactUnit = EffectTemplate.CMolecularResonanceHitUnit01,
    FxImpactProp = EffectTemplate.CMolecularResonanceHitUnit01,
    FxImpactLand = EffectTemplate.CMolecularResonanceHitUnit01,
    DestroyOnImpact = false,

    ---@param self CIFMolecularResonanceShell
    OnCreate = function(self)
        SinglePolyTrailProjectile.OnCreate(self)
        self.Impacted = false
    end,

    ---@param self CIFMolecularResonanceShell
    DelayedDestroyThread = function(self)
        WaitTicks(4)
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
                self.Trash:Add(ForkThread(self.DelayedDestroyThread,self))
            else
                SinglePolyTrailProjectile.OnImpact(self, TargetType, TargetEntity)
                self:Destroy()
            end
        end
    end,
}

--- IRIDIUM ROCKET PROJECTILES
--- T2 gs & SR & hoplite
---@class CIridiumRocketProjectile : SingleCompositeEmitterProjectile
CIridiumRocketProjectile = ClassProjectile(SingleCompositeEmitterProjectile) {
    PolyTrail = '/effects/emitters/cybran_iridium_missile_polytrail_01_emit.bp',
    BeamName = '/effects/emitters/rocket_iridium_exhaust_beam_01_emit.bp',
    FxImpactUnit = EffectTemplate.CMissileHit02,
    FxImpactProp = EffectTemplate.CMissileHit02,
    FxImpactLand = EffectTemplate.CMissileHit02,
}

---  CORSAIR MISSILE PROJECTILES
---@class CCorsairRocketProjectile : SingleCompositeEmitterProjectile
CCorsairRocketProjectile = ClassProjectile(SingleCompositeEmitterProjectile) {
    PolyTrail = EffectTemplate.CCorsairMissilePolyTrail01,
    BeamName = '/effects/emitters/rocket_iridium_exhaust_beam_01_emit.bp',
    FxImpactUnit = EffectTemplate.CCorsairMissileUnitHit01,
    FxImpactProp = EffectTemplate.CCorsairMissileHit01,
    FxImpactLand = EffectTemplate.CCorsairMissileLandHit01,
}

---  CYBRAN LASER PROJECILES
---@class CLaserLaserProjectile : MultiPolyTrailProjectile
CLaserLaserProjectile = ClassProjectile(MultiPolyTrailProjectile) {
    PolyTrails = {
        '/effects/emitters/cybran_laser_trail_01_emit.bp',
        '/effects/emitters/default_polytrail_02_emit.bp',
    },
    PolyTrailOffset = { 0, 0 },
    FxImpactUnit = EffectTemplate.CLaserHitUnit01,
    FxImpactProp = EffectTemplate.CLaserHitUnit01,
    FxImpactLand = EffectTemplate.CLaserHitLand01,
}

---@class CHeavyLaserProjectile : MultiPolyTrailProjectile
CHeavyLaserProjectile = ClassProjectile(MultiPolyTrailProjectile) {
    PolyTrails = {
        '/effects/emitters/cybran_laser_trail_02_emit.bp',
        '/effects/emitters/default_polytrail_03_emit.bp',
    },
    PolyTrailOffset = { 0, 0 },
    FxImpactUnit = EffectTemplate.CLaserHitUnit01,
    FxImpactProp = EffectTemplate.CLaserHitUnit01,
    FxImpactLand = EffectTemplate.CLaserHitLand01,
}

---@class CHeavyLaserProjectile2 : MultiPolyTrailProjectile
CHeavyLaserProjectile2 = ClassProjectile(MultiPolyTrailProjectile) {
    PolyTrails = {
        '/effects/emitters/hrailgunsd_polytrail_01_emit.bp',
                '/effects/emitters/default_polytrail_02_emit.bp',
    },
    PolyTrailOffset = { 0, 0 },
    FxUnitHitScale = 0.15,
    FxLandHitScale = 0.15,
    FxImpactUnit = EffectTemplate.CBeamHitUnit01,
    FxImpactProp = EffectTemplate.CBeamHitUnit01,
    FxImpactLand = EffectTemplate.CBeamHitLand01,
}

---  CYBRAN MOLECULAR CANNON PROJECTILE
--- ACU
---@class CMolecularCannonProjectile : SinglePolyTrailProjectile
CMolecularCannonProjectile = ClassProjectile(SinglePolyTrailProjectile) {
    FxImpactTrajectoryAligned = false,
    PolyTrail = '/effects/emitters/default_polytrail_03_emit.bp',
    FxTrails = EffectTemplate.CMolecularCannon01,
    FxImpactUnit = EffectTemplate.CMolecularRipperHit01,
    FxImpactProp = EffectTemplate.CMolecularRipperHit01,
    FxImpactLand = EffectTemplate.CMolecularRipperHit01,
}

---  CYBRAN AA MISSILE PROJECILES - Air Targets
---@class CMissileAAProjectile : SingleCompositeEmitterProjectile
CMissileAAProjectile = ClassProjectile(SingleCompositeEmitterProjectile) {
    TrailDelay = 1,
    FxTrails = {'/effects/emitters/missile_sam_munition_trail_01_emit.bp',},
    FxTrailOffset = 0.5,
    BeamName = '/effects/emitters/missile_sam_munition_exhaust_beam_01_emit.bp',
    FxUnitHitScale = 0.5,
    FxImpactUnit = EffectTemplate.CMissileHit01,
    FxImpactProp = EffectTemplate.CMissileHit01,
    FxLandHitScale = 0.5,
    FxImpactLand = EffectTemplate.CMissileHit01,

    OnCreate = function(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)
        SingleBeamProjectile.OnCreate(self)
    end,
}

---  NEUTRON CLUSTER BOMB PROJECTILES
---@class CNeutronClusterBombChildProjectile : SinglePolyTrailProjectile
CNeutronClusterBombChildProjectile = ClassProjectile(SinglePolyTrailProjectile) {
    PolyTrail = '/effects/emitters/default_polytrail_05_emit.bp',
    FxImpactUnit = EffectTemplate.CNeutronClusterBombHitUnit01,
    FxImpactProp = EffectTemplate.CNeutronClusterBombHitUnit01,
    FxImpactLand = EffectTemplate.CNeutronClusterBombHitLand01,
    FxImpactWater = EffectTemplate.CNeutronClusterBombHitWater01,

    --- No damage dealt by this child.
    ---@param self CNeutronClusterBombChildProjectile
    ---@param instigator Weapon
    ---@param damageData table
    ---@param targetEntity Unit
    DoDamage = function(self, instigator, damageData, targetEntity)
    end,
}

---@class CNeutronClusterBombProjectile : SinglePolyTrailProjectile
CNeutronClusterBombProjectile = ClassProjectile(SinglePolyTrailProjectile) {
    PolyTrail = '/effects/emitters/default_polytrail_03_emit.bp',
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
        self.Trash:Add(ForkThread(self.DelayedDestroyThread, self))
    end,

    ---@param self CNeutronClusterBombProjectile
    DelayedDestroyThread = function(self)
        WaitTicks(6)
        self:Destroy()
    end,
}

---  CYBRAN MACHINE GUN SHELLS
---@class CParticleCannonProjectile : SingleBeamProjectile
CParticleCannonProjectile = ClassProjectile(SingleBeamProjectile) {
    BeamName = '/effects/emitters/laserturret_munition_beam_01_emit.bp',
    FxImpactUnit = EffectTemplate.CParticleCannonHitUnit01,
    FxImpactProp = EffectTemplate.CParticleCannonHitUnit01,
    FxImpactLand = EffectTemplate.CParticleCannonHitLand01,
}

---  CYBRAN RAIL GUN PROJECTILES
---@class CRailGunProjectile : EmitterProjectile
CRailGunProjectile = ClassProjectile(EmitterProjectile) {
    FxTrails = {'/effects/emitters/railgun_munition_trail_02_emit.bp',
                '/effects/emitters/railgun_munition_trail_01_emit.bp'},
    FxTrailScale = 0,
    FxTrailOffset = 0,
}

---  CYBRAN ROCKET PROJECILES
--- wagner
---@class CRocketProjectile : SingleBeamProjectile
CRocketProjectile = ClassProjectile(SingleBeamProjectile) {
    BeamName = '/effects/emitters/rocket_iridium_exhaust_beam_01_emit.bp',
    FxImpactUnit = EffectTemplate.CMissileHit01,
    FxImpactProp = EffectTemplate.CMissileHit01,
    FxImpactLand = EffectTemplate.CMissileHit01,
}

---  CYBRAN ROCKET PROJECILES
---@class CLOATacticalMissileProjectile : SingleBeamProjectile, TacticalMissileComponent, SplitComponent, DebrisComponent
CLOATacticalMissileProjectile = ClassProjectile(SingleBeamProjectile, TacticalMissileComponent, SplitComponent, DebrisComponent) {
    BeamName = '/effects/emitters/missile_loa_munition_exhaust_beam_01_emit.bp',
    FxTrails = {'/effects/emitters/missile_cruise_munition_trail_01_emit.bp',},
    FxTrailOffset = -0.5,
    FxExitWaterEmitter = EffectTemplate.TIFCruiseMissileLaunchExitWater,

    FxImpactUnit = EffectTemplate.CMissileLOAHit01,
    FxImpactLand = EffectTemplate.CMissileLOAHit01,
    FxImpactProp = EffectTemplate.CMissileLOAHit01,

    FxImpactNone = EffectTemplate.TMissileKilled01,
    FxNoneHitScale = 0.6,

    FxOnKilled = EffectTemplate.TMissileKilled01,
    FxOnKilledScale = 0.6,

    LaunchTicks = 2,
    LaunchTurnRate = 6,
    HeightDistanceFactor = 5,
    MinHeight = 2,
    FinalBoostAngle = 0,

    ChildCount = 3,
    ChildProjectileBlueprint = '/projectiles/CIFMissileTacticalSplit01/CIFMissileTacticalSplit01_proj.bp',

    DebrisBlueprints = {
        '/effects/Entities/TacticalDebris01/TacticalDebris01_proj.bp',
        '/effects/Entities/TacticalDebris01/TacticalDebris01_proj.bp',
        '/effects/Entities/TacticalDebris02/TacticalDebris02_proj.bp',
    },

    ---@param self CLOATacticalMissileProjectile
    ---@param inWater boolean
    OnCreate = function(self, inWater)
        SingleBeamProjectile.OnCreate(self, inWater)
        
        local blueprintPhysics = self.Blueprint.Physics
        local radius = 0.105 * (blueprintPhysics.MaxSpeed + blueprintPhysics.MaxSpeedRange)
        self:SetCollisionShape('Sphere', 0, 0, 0, radius)
    end,

    ---@param self CLOATacticalMissileProjectile
    ---@param instigator Unit
    ---@param type string
    ---@param overkillRatio number
    OnKilled = function(self, instigator, type, overkillRatio)
        SingleBeamProjectile.OnKilled(self, instigator, type, overkillRatio)

        CreateLightParticle(self, -1, self.Army, 3, 6, 'flare_lens_add_02', 'ramp_fire_11')
        self:CreateDebris()
    end,

    ---@param self CLOATacticalMissileProjectile
    ---@param instigator Unit | Projectile
    ---@param amount number
    ---@param vector Vector
    ---@param damageType DamageType
    OnDamage = function(self, instigator, amount, vector, damageType)
        SingleBeamProjectile.OnDamage(self, instigator, amount, vector, damageType)

        if self:GetHealth() <= 0 then
            self.DamageData.DamageAmount = self.Launcher.Blueprint.SplitDamage.DamageAmount or 0
            self.DamageData.DamageRadius = self.Launcher.Blueprint.SplitDamage.DamageRadius or 1

            self:OnSplit(true)
        end
    end,

    ---@param self CLOATacticalMissileProjectile
    ---@param targetType string
    ---@param targetEntity Unit
    OnImpact = function(self, targetType, targetEntity)
        SingleBeamProjectile.OnImpact(self, targetType, targetEntity)

        CreateLightParticle(self, -1, self.Army, 3, 6, 'flare_lens_add_02', 'ramp_fire_11')
        if targetType == 'None' or targetType == 'Air' then
            self:CreateDebris()
        end
    end,
}

---  CYBRAN ROCKET PROJECILES
---@class CLOATacticalChildMissileProjectile : SingleBeamProjectile, TacticalMissileComponent, DebrisComponent
CLOATacticalChildMissileProjectile = ClassProjectile(SingleBeamProjectile, TacticalMissileComponent, DebrisComponent) {
    BeamName = '/effects/emitters/missile_loa_munition_exhaust_beam_02_emit.bp',
    FxTrails = {'/effects/emitters/missile_cruise_munition_trail_03_emit.bp',},
    FxTrailOffset = -0.5,
    FxExitWaterEmitter = EffectTemplate.TIFCruiseMissileLaunchExitWater,
    FxImpactUnit = EffectTemplate.CMissileLOAHit01,
    FxImpactLand = EffectTemplate.CMissileLOAHit01,
    FxImpactProp = EffectTemplate.CMissileLOAHit01,
    FxAirUnitHitScale = 0.375,
    FxLandHitScale = 0.375,
    FxPropHitScale = 0.375,
    FxProjectileHitScale = 0.375,
    FxShieldHitScale = 0.375,
    FxUnitHitScale = 0.375,
    FxWaterHitScale = 0.375,

    FxImpactNone = EffectTemplate.TMissileKilled01,
    FxNoneHitScale = 0.375,

    FxOnKilled = EffectTemplate.TMissileKilled01,
    FxOnKilledScale = 0.375,

    LaunchTicks = 2,
    LaunchTurnRate = 6,
    HeightDistanceFactor = 5,
    MinHeight = 2,
    FinalBoostAngle = 0,

    DebrisBlueprints = {
        '/effects/Entities/TacticalDebris03/TacticalDebris03_proj.bp',
    },

    ---@param self CLOATacticalChildMissileProjectile
    OnCreate = function(self)
        SingleBeamProjectile.OnCreate(self)

        local blueprintPhysics = self.Blueprint.Physics
        local radius = 0.105 * (blueprintPhysics.MaxSpeed + blueprintPhysics.MaxSpeedRange)
        self:SetCollisionShape('Sphere', 0, 0, 0, radius)
    end,

    ---@param self CLOATacticalChildMissileProjectile
    ---@param instigator Unit
    ---@param type string
    ---@param overkillRatio number
    OnKilled = function(self, instigator, type, overkillRatio)
        SingleBeamProjectile.OnKilled(self, instigator, type, overkillRatio)

        CreateLightParticle(self, -1, self.Army, 3, 6, 'flare_lens_add_02', 'ramp_fire_11')
        self:CreateDebris()
    end,

    ---@param self CLOATacticalChildMissileProjectile
    ---@param targetType string
    ---@param targetEntity Unit
    OnImpact = function(self, targetType, targetEntity)
        SingleBeamProjectile.OnImpact(self, targetType, targetEntity)

        CreateLightParticle(self, -1, self.Army, 3, 6, 'flare_lens_add_02', 'ramp_fire_11')
        if targetType == 'None' then
            self:CreateDebris()
        end
    end,
}

---  CYBRAN AUTOCANNON PROJECILES
---@class CShellAAAutoCannonProjectile : MultiPolyTrailProjectile
CShellAAAutoCannonProjectile = ClassProjectile(MultiPolyTrailProjectile) {
    PolyTrails = {
        '/effects/emitters/auto_cannon_trail_01_emit.bp',
        '/effects/emitters/default_polytrail_03_emit.bp',
    },
    PolyTrailOffset = { 0, 0 },
    FxImpactUnit = {'/effects/emitters/auto_cannon_hit_flash_01_emit.bp'},
    FxImpactProp ={'/effects/emitters/auto_cannon_hit_flash_01_emit.bp'},
    FxImpactAirUnit = {'/effects/emitters/auto_cannon_hit_flash_01_emit.bp'},
}

---  CYBRAN RIOT PROJECILES
---@class CShellRiotProjectile : SingleBeamProjectile
CShellRiotProjectile = ClassProjectile(SingleBeamProjectile) {
    BeamName = '/effects/emitters/riotgun_munition_beam_01_emit.bp',
    FxImpactUnit = {'/effects/emitters/destruction_explosion_sparks_01_emit.bp',},
    FxImpactProp = {'/effects/emitters/destruction_explosion_sparks_01_emit.bp',},
    FxLandHitScale = 3,
    FxImpactLand = {'/effects/emitters/destruction_land_hit_puff_01_emit.bp',},
}

---  CYBRAN ABOVE WATER LAUNCHED TORPEDO
---@class CTorpedoShipProjectile : OnWaterEntryEmitterProjectile
CTorpedoShipProjectile = ClassProjectile(OnWaterEntryEmitterProjectile) {
    FxSplashScale = 0.5,
    FxTrails = {'/effects/emitters/torpedo_munition_trail_01_emit.bp',},
    FxTrailScale = 1.25,
    FxTrailOffset = 0.2,
    FxEnterWater= { '/effects/emitters/water_splash_ripples_ring_01_emit.bp',
                    '/effects/emitters/water_splash_plume_01_emit.bp',
    },
    FxUnitHitScale = 1.25,
    FxImpactUnit = EffectTemplate.CTorpedoUnitHit01,
    FxImpactProp = EffectTemplate.CTorpedoUnitHit01,
    FxImpactUnderWater = EffectTemplate.CTorpedoUnitHit01,

    --- if we are starting in the water then immediately switch to tracking in water
    ---@param self CTorpedoShipProjectile
    ---@param inWater boolean
    OnCreate = function(self, inWater)
        OnWaterEntryEmitterProjectile.OnCreate(self, inWater)

        if inWater == true then
            self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)
        end
    end,

    ---@param self CTorpedoShipProjectile
    OnEnterWater = function(self)
        OnWaterEntryEmitterProjectile.OnEnterWater(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)
    end,
}

---  CYBRAN SUB LAUNCHED TORPEDO
---@class CTorpedoSubProjectile : EmitterProjectile
CTorpedoSubProjectile = ClassProjectile(EmitterProjectile) {
    FxTrails = {'/effects/emitters/torpedo_underwater_wake_02_emit.bp',},
    FxUnitHitScale = 1.25,
    FxImpactUnit = EffectTemplate.CTorpedoUnitHit01,
    FxImpactProp = EffectTemplate.CTorpedoUnitHit01,
    FxImpactUnderWater = EffectTemplate.CTorpedoUnitHit01,
    FxImpactLand = EffectTemplate.CTorpedoUnitHit01,
    FxLandHitScale = 0.25,
    FxNoneHitScale = 1,

    ---@param self CTorpedoSubProjectile
    ---@param inWater boolean
    OnCreate = function(self, inWater)
        self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)
        EmitterProjectile.OnCreate(self, inWater)
    end,
}

---  Cybran DEPTH CHARGE PROJECTILES
---@class CDepthChargeProjectile : OnWaterEntryEmitterProjectile
CDepthChargeProjectile = ClassProjectile(OnWaterEntryEmitterProjectile) {
    FxTrails = {
        '/effects/emitters/anti_torpedo_flare_01_emit.bp',
        '/effects/emitters/anti_torpedo_flare_02_emit.bp',
    },
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
}

--------------------------------------------------------------------------
--
--  SC1 EXPANSION PROJECTILES
--
--------------------------------------------------------------------------

--- Brick
---@class CHeavyDisintegratorPulseLaser : MultiPolyTrailProjectile
CHeavyDisintegratorPulseLaser = ClassProjectile(MultiPolyTrailProjectile) {
    PolyTrails = {
        '/effects/emitters/disintegrator_polytrail_02_emit.bp',
        '/effects/emitters/disintegrator_polytrail_03_emit.bp',
        '/effects/emitters/default_polytrail_03_emit.bp',
    },
    PolyTrailOffset = { 0, 0, 0 },
    FxImpactUnit = EffectTemplate.CHvyDisintegratorHitUnit01,
    FxImpactProp = EffectTemplate.CHvyDisintegratorHitUnit01,
    FxImpactLand = EffectTemplate.CHvyDisintegratorHitLand01,
    FxTrailOffset = 0,
}


---@class CKrilTorpedo : OnWaterEntryEmitterProjectile
CKrilTorpedo = ClassProjectile(OnWaterEntryEmitterProjectile) {}

-- kept for mod backwards compatibility
local DefaultExplosion = import("/lua/defaultexplosions.lua")
local RandomFloat = import("/lua/utilities.lua").GetRandomFloat
local MultiBeamProjectile = DefaultProjectileFile.MultiBeamProjectile
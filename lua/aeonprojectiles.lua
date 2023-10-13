------------------------------------------------------------
--  File     :  /lua/aeonprojectiles.lua
--  Author(s):  John Comes, Gordon Duclos
--
--  Summary  : Aeon base projectile definitions
--
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------

local DefaultProjectileFile = import("/lua/sim/defaultprojectiles.lua")
local EmitterProjectile = DefaultProjectileFile.EmitterProjectile
local OnWaterEntryEmitterProjectile = DefaultProjectileFile.OnWaterEntryEmitterProjectile
local SingleBeamProjectile = DefaultProjectileFile.SingleBeamProjectile
local SinglePolyTrailProjectile = DefaultProjectileFile.SinglePolyTrailProjectile
local MultiPolyTrailProjectile = DefaultProjectileFile.MultiPolyTrailProjectile
local SingleCompositeEmitterProjectile = DefaultProjectileFile.SingleCompositeEmitterProjectile
local MultiCompositeEmitterProjectile = DefaultProjectileFile.MultiCompositeEmitterProjectile
local NullShell = DefaultProjectileFile.NullShell
local DepthCharge = import("/lua/defaultantiprojectile.lua").DepthCharge
local EffectTemplate = import("/lua/effecttemplates.lua")
local NukeProjectile = DefaultProjectileFile.NukeProjectile

local DebrisComponent = import('/lua/sim/projectiles/components/DebrisComponent.lua').DebrisComponent
local TacticalMissileComponent = import('/lua/sim/DefaultProjectiles.lua').TacticalMissileComponent

--- AEON ANTI-NUKE PROJECTILES
---@class ASaintAntiNuke : SinglePolyTrailProjectile
ASaintAntiNuke = ClassProjectile(SinglePolyTrailProjectile) {
    PolyTrail = '/effects/emitters/aeon_missile_trail_02_emit.bp',
    FxTrails = {'/effects/emitters/saint_munition_01_emit.bp'},
    FxImpactUnit = EffectTemplate.AMissileHit01,
    FxImpactProp = EffectTemplate.AMissileHit01,
    FxImpactNone = EffectTemplate.AMissileHit01,
    FxImpactLand = EffectTemplate.AMissileHit01,
    FxImpactProjectile = EffectTemplate.ASaintImpact01,
}

--- AEON Ballistic Mortar Launcher
---@class AIFBallisticMortarProjectile : EmitterProjectile
AIFBallisticMortarProjectile = ClassProjectile(EmitterProjectile) {
    FxTrails = EffectTemplate.AQuarkBomb01,
    FxImpactUnit =  EffectTemplate.AIFBallisticMortarHit01,
    FxImpactProp =  EffectTemplate.AIFBallisticMortarHit01,
    FxImpactLand =  EffectTemplate.AIFBallisticMortarHit01,
    FxImpactAirUnit =  EffectTemplate.AIFBallisticMortarHit01,
}

--- AEON Ballistic Mortar Launcher
---@class AIFBallisticMortarProjectile02 : MultiPolyTrailProjectile
AIFBallisticMortarProjectile02 = ClassProjectile(MultiPolyTrailProjectile) {
    PolyTrails = EffectTemplate.AIFBallisticMortarTrails02,
    PolyTrailOffset = { 0, 0 },
    FxTrails = EffectTemplate.AIFBallisticMortarFxTrails02,
    FxImpactUnit =  EffectTemplate.AIFBallisticMortarHitUnit02,
    FxImpactProp =  EffectTemplate.AIFBallisticMortarHitUnit02,
    FxImpactLand =  EffectTemplate.AIFBallisticMortarHitLand02,
}

--- AEON ARTILLERY PROJECTILES
---@class AArtilleryProjectile : EmitterProjectile
AArtilleryProjectile = ClassProjectile(EmitterProjectile) {
    FxTrails = EffectTemplate.AIFBallisticMortarTrails01,
    FxTrailScale = 0.75,
    FxImpactUnit =  EffectTemplate.AQuarkBombHitUnit01,
    FxImpactProp =  EffectTemplate.AQuarkBombHitUnit01,
    FxImpactLand =  EffectTemplate.AQuarkBombHitLand01,
    FxImpactAirUnit =  EffectTemplate.AQuarkBombHitAirUnit01,
}

--- AEON BEAM PROJECTILES
---@class ABeamProjectile : NullShell
ABeamProjectile = ClassProjectile(NullShell) {
    FxUnitHitScale = 0.5,
    FxImpactUnit = EffectTemplate.ABeamHitUnit01,
    FxImpactProp = EffectTemplate.ABeamHitUnit01,
    FxImpactLand = EffectTemplate.ABeamHitLand01,
}

--- AEON GRAVITON BOMB
--- used by T1 bomber
---@class AGravitonBombProjectile : SinglePolyTrailProjectile
AGravitonBombProjectile = ClassProjectile(SinglePolyTrailProjectile) { 
    PolyTrail = '/effects/emitters/default_polytrail_03_emit.bp',
    FxTrails = {'/effects/emitters/torpedo_munition_trail_01_emit.bp',},
    FxImpactUnit = EffectTemplate.ABombHit01,
    FxImpactProp = EffectTemplate.ABombHit01,
    FxImpactLand = EffectTemplate.ABombHit01,
}

--- AEON SHIP PROJECTILES
---@class ACannonSeaProjectile : SingleBeamProjectile
ACannonSeaProjectile = ClassProjectile(SingleBeamProjectile) {
    BeamName = '/effects/emitters/cannon_munition_ship_aeon_beam_01_emit.bp',
}

--- AEON TANK PROJECTILES
---@class ACannonTankProjectile : SingleBeamProjectile
ACannonTankProjectile = ClassProjectile(SingleBeamProjectile) {
    BeamName = '/effects/emitters/cannon_munition_ship_aeon_beam_01_emit.bp',
}

--- AEON DEPTH CHARGE
---@class ADepthChargeProjectile : OnWaterEntryEmitterProjectile
ADepthChargeProjectile = ClassProjectile(OnWaterEntryEmitterProjectile) {
    FxTrails = {'/effects/emitters/torpedo_munition_trail_01_emit.bp',},
    TrailDelay = 0,
    TrackTime = 0,
    FxImpactUnit = EffectTemplate.ADepthChargeHitUnit01,
    FxImpactProp = EffectTemplate.ADepthChargeHitUnit01,
    FxImpactUnderWater = EffectTemplate.ADepthChargeHitUnderWaterUnit01,

    OnEnterWater = function(self)
        OnWaterEntryEmitterProjectile.OnEnterWater(self)
        self:SetMaxSpeed(20)
        self:SetAcceleration(5)
        self:SetTurnRate(180)
        self:SetVelocity(0.5)
    end,
}

--- AEON ARTILLERY PROJECTILES
---@class AGravitonProjectile : EmitterProjectile
AGravitonProjectile = ClassProjectile(EmitterProjectile) {
    FxTrails = {'/effects/emitters/graviton_munition_trail_01_emit.bp',},
    FxImpactUnit = EffectTemplate.AGravitonBolterHit01,
    FxImpactLand = EffectTemplate.AGravitonBolterHit01,
    FxImpactProp = EffectTemplate.AGravitonBolterHit01,
    DirectionalImpactEffect = {'/effects/emitters/graviton_bolter_hit_01_emit.bp',},
}

--- AEON LASER PROJECTILES
---@class AHighIntensityLaserProjectile : SinglePolyTrailProjectile
AHighIntensityLaserProjectile = ClassProjectile(SinglePolyTrailProjectile) {
    FxTrails = {
        '/effects/emitters/aeon_laser_fxtrail_01_emit.bp',
        '/effects/emitters/aeon_laser_fxtrail_02_emit.bp',
    },
    PolyTrail = '/effects/emitters/aeon_laser_trail_01_emit.bp',
    FxImpactUnit = EffectTemplate.AHighIntensityLaserHitUnit01,
    FxImpactProp = EffectTemplate.AHighIntensityLaserHitUnit01,
    FxImpactLand = EffectTemplate.AHighIntensityLaserHitLand01,
}

--- AEON FLARE PROJECTILES
---@class AIMFlareProjectile : EmitterProjectile
AIMFlareProjectile = ClassProjectile(EmitterProjectile) {
    FxTrails = EffectTemplate.AAntiMissileFlare,
    FxTrailScale = 1.0,
    FxImpactNone = EffectTemplate.AAntiMissileFlareHit,
    FxImpactProjectile = EffectTemplate.AAntiMissileFlareHit,
    FxOnKilled = EffectTemplate.AAntiMissileFlareHit,
    FxUnitHitScale = 0.4,
    FxLandHitScale = 0.4,
    FxWaterHitScale = 0.4,
    FxUnderWaterHitScale = 0.4,
    FxAirUnitHitScale = 0.4,
    FxNoneHitScale = 0.4,
    DestroyOnImpact = false,

    ---@param self AIMAntiMissile01
    ---@param other Projectile
    ---@return boolean
    OnCollisionCheck = function(self, other)
        other.DamageData.Damage = 0
        return true
    end,
}

--- AEON LASER PROJECTILES
---@class ALaserBotProjectile : SinglePolyTrailProjectile
ALaserBotProjectile = ClassProjectile(SinglePolyTrailProjectile) {
    PolyTrail = '/effects/emitters/aeon_laser_trail_01_emit.bp',
    FxImpactUnit = EffectTemplate.ALaserBotHitUnit01,
    FxImpactProp = EffectTemplate.ALaserBotHitUnit01,
    FxImpactLand = EffectTemplate.ALaserBotHitLand01,
}

--- AEON LASER PROJECTILES
---@class ALaserProjectile : SingleBeamProjectile
ALaserProjectile = ClassProjectile(SingleBeamProjectile) {
    BeamName = '/effects/emitters/laserturret_munition_beam_02_emit.bp',
    FxImpactUnit = EffectTemplate.ALaserHitUnit01,
    FxImpactProp = EffectTemplate.ALaserHitUnit01,
    FxImpactLand = EffectTemplate.ALaserHitLand01,
}

--- AEON LASER PROJECTILES
---@class AQuadLightLaserProjectile : MultiPolyTrailProjectile
AQuadLightLaserProjectile = ClassProjectile(MultiPolyTrailProjectile) {

    PolyTrails = {
        '/effects/emitters/aeon_laser_trail_02_emit.bp',
        '/effects/emitters/default_polytrail_03_emit.bp',
    },
    PolyTrailOffset = { 0, 0 },
    FxImpactUnit = EffectTemplate.ALightLaserHitUnit01,
    FxImpactProp = EffectTemplate.ALightLaserHitUnit01,
    FxImpactLand = EffectTemplate.ALightLaserHit01,
}

--- AEON LASER PROJECTILES
---@class ALightLaserProjectile : MultiPolyTrailProjectile
ALightLaserProjectile = ClassProjectile(MultiPolyTrailProjectile) {
    PolyTrails = {
        '/effects/emitters/aeon_laser_trail_02_emit.bp',
        '/effects/emitters/default_polytrail_03_emit.bp',
    },
    PolyTrailOffset = { 0, 0 },
    FxImpactUnit = EffectTemplate.ALightLaserHitUnit01,
    FxImpactProp = EffectTemplate.ALightLaserHitUnit01,
    FxImpactLand = EffectTemplate.ALightLaserHit01,
}

--- AEON LASER PROJECTILES
---@class ASonicPulsarProjectile : EmitterProjectile
ASonicPulsarProjectile = ClassProjectile(EmitterProjectile){
    FxTrails = EffectTemplate.ASonicPulsarMunition01,
}

--- AEON ARTILLERY PROJECTILES
---@class AMiasmaProjectile : EmitterProjectile
AMiasmaProjectile = ClassProjectile(EmitterProjectile) {
    FxTrails = EffectTemplate.AMiasmaMunition01,
    FxImpactNone = EffectTemplate.AMiasma01,
}

--- AEON ARTILLERY PROJECTILES
---@class AMiasmaProjectile02 : EmitterProjectile
AMiasmaProjectile02 = ClassProjectile(EmitterProjectile) {
    FxTrails = EffectTemplate.AMiasmaMunition02,
    FxImpactLand = EffectTemplate.AMiasmaField01,
    FxImpactUnit = EffectTemplate.AMiasmaField01,
    FxImpactProp = EffectTemplate.AMiasmaField01,
}

--- AEON AA MISSILE PROJECTILES
---@class AMissileAAProjectile : SinglePolyTrailProjectile
AMissileAAProjectile = ClassProjectile(SinglePolyTrailProjectile) {
    PolyTrail = '/effects/emitters/aeon_missile_trail_01_emit.bp',
    FxImpactUnit = EffectTemplate.AMissileHit01,
    FxImpactAirUnit = EffectTemplate.AMissileHit01,
    FxImpactProp = EffectTemplate.AMissileHit01,
    FxImpactNone = EffectTemplate.AMissileHit01,
    FxImpactLand = EffectTemplate.AMissileHit01,
}

--- AEON AA MISSILE PROJECTILES
---@class AZealot02AAMissileProjectile : SinglePolyTrailProjectile
AZealot02AAMissileProjectile = ClassProjectile(SinglePolyTrailProjectile) {
    PolyTrail = '/effects/emitters/aeon_missile_trail_03_emit.bp',
    FxImpactUnit = EffectTemplate.AMissileHit01,
    FxImpactAirUnit = EffectTemplate.AMissileHit01,
    FxImpactProp = EffectTemplate.AMissileHit01,
    FxImpactNone = EffectTemplate.AMissileHit01,
    FxImpactLand = EffectTemplate.AMissileHit01,
}

--- AEON AA MISSILE PROJECTILES
---@class AAALightDisplacementAutocannonMissileProjectile : MultiPolyTrailProjectile
AAALightDisplacementAutocannonMissileProjectile = ClassProjectile(MultiPolyTrailProjectile) {
    FxImpactUnit = EffectTemplate.ALightDisplacementAutocannonMissileHit,
    FxImpactAirUnit = EffectTemplate.ALightDisplacementAutocannonMissileHitUnit,
    FxImpactProp = EffectTemplate.ALightDisplacementAutocannonMissileHit,
    FxImpactNone = EffectTemplate.ALightDisplacementAutocannonMissileHit,
    FxImpactLand = EffectTemplate.ALightDisplacementAutocannonMissileHit,
    PolyTrails = EffectTemplate.ALightDisplacementAutocannonMissilePolyTrails,
    PolyTrailOffset = { 0, 0 },
}

--- AEON GUIDED MISSILE PROJECTILES
---@class AGuidedMissileProjectile : SinglePolyTrailProjectile
AGuidedMissileProjectile = ClassProjectile(SinglePolyTrailProjectile) {
    FxTrails =  EffectTemplate.AMercyGuidedMissileFxTrails,
    PolyTrail = EffectTemplate.AMercyGuidedMissilePolyTrail,
    FxImpactUnit = EffectTemplate.AMercyGuidedMissileSplitMissileHitUnit,
    FxImpactProp = EffectTemplate.AMercyGuidedMissileSplitMissileHit,
    FxImpactNone = EffectTemplate.AMercyGuidedMissileSplitMissileHit,
    FxImpactLand = EffectTemplate.AMercyGuidedMissileSplitMissileHitLand,
}

--- AEON SUB-LAUNCHED CRUISE MISSILE PROJECTILES
---@class AMissileCruiseSubProjectile : EmitterProjectile
AMissileCruiseSubProjectile = ClassProjectile(EmitterProjectile) {
    FxUnderWaterTrail = {'/effects/emitters/missile_cruise_munition_underwater_trail_01_emit.bp',},
    FxExitWaterEmitter = EffectTemplate.DefaultProjectileWaterImpact,
    FxSplashScale = 0.65,
    ExitWaterTicks = 9,
    FxTrailOffset = -0.5,
    FxTrails = {'/effects/emitters/missile_cruise_munition_trail_01_emit.bp',},
    FxImpactUnit = EffectTemplate.AMissileHit01,
    FxImpactProp = EffectTemplate.AMissileHit01,
    FxImpactLand = EffectTemplate.AMissileHit01,

    ---@param self AMissileCruiseSubProjectile
    OnCreate = function(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)
        SinglePolyTrailProjectile.OnCreate(self)
    end,
}

--- AEON SERPENTINE MISSILE PROJECTILES
---@class AMissileSerpentineProjectile : SingleCompositeEmitterProjectile, TacticalMissileComponent, DebrisComponent
AMissileSerpentineProjectile = ClassProjectile(SingleCompositeEmitterProjectile, TacticalMissileComponent, DebrisComponent) {
    PolyTrail = '/effects/emitters/serpentine_missile_trail_emit.bp',
    BeamName = '/effects/emitters/serpentine_missle_exhaust_beam_01_emit.bp',

    PolyTrailOffset = -0.05,

    FxImpactUnit = EffectTemplate.AMissileHit01,
    FxImpactProp = EffectTemplate.AMissileHit01,
    FxImpactLand = EffectTemplate.AMissileHit01,

    FxOnKilled = EffectTemplate.AMissileHit01,
    FxOnKilledScale = 0.6,

    FxImpactNone = EffectTemplate.AMissileHit01,
    FxNoneHitScale = 0.6,

    FxExitWaterEmitter = EffectTemplate.TIFCruiseMissileLaunchExitWater,

    LaunchTicks = 2,
    LaunchTurnRate = 6,
    HeightDistanceFactor = 5,
    MinHeight = 2,
    FinalBoostAngle = 20,

    ---@param self AMissileSerpentineProjectile
    OnCreate = function(self)
        SingleCompositeEmitterProjectile.OnCreate(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 2)
    end,

    ---@param self AMissileSerpentineProjectile
    ---@param instigator Unit
    ---@param type string
    ---@param overkillRatio number
    OnKilled = function(self, instigator, type, overkillRatio)
        SingleCompositeEmitterProjectile.OnKilled(self, instigator, type, overkillRatio)

        self:CreateDebris()
        CreateLightParticle(self, -1, self.Army, 3, 6, 'flare_lens_add_02', 'ramp_aeon_02')
    end,

    ---@param self AMissileSerpentineProjectile
    ---@param targetType string
    ---@param targetEntity Prop|Unit
    OnImpact = function(self, targetType, targetEntity)
        SingleCompositeEmitterProjectile.OnImpact(self, targetType, targetEntity)

        if targetType == 'None' then
            self:CreateDebris()
        end

        CreateLightParticle(self, -1, self.Army, 4, 4, 'flare_lens_add_02', 'ramp_aeon_02')
    end,

    OnExitWater = function(self)
        SingleCompositeEmitterProjectile.OnExitWater(self)
        self:SetDestroyOnWater(true)
    end,
}

--- AEON SERPENTINE MISSILE PROJECTILES
---@class AMissileSerpentine02Projectile : AMissileSerpentineProjectile
AMissileSerpentine02Projectile = AMissileSerpentineProjectile

--- AEON OBLIVION PROJECILE
---@class AOblivionCannonProjectile : EmitterProjectile
AOblivionCannonProjectile = ClassProjectile(EmitterProjectile) {
    FxTrails = {'/effects/emitters/oblivion_cannon_munition_01_emit.bp'},
    FxImpactUnit = EffectTemplate.AOblivionCannonHit01,
    FxImpactProp = EffectTemplate.AOblivionCannonHit01,
    FxImpactLand = EffectTemplate.AOblivionCannonHit01,
    FxImpactWater = EffectTemplate.AOblivionCannonHit01,
}

--- AEON OBLIVION PROJECILE
---@class AOblivionCannonProjectile02 : SinglePolyTrailProjectile
AOblivionCannonProjectile02 = ClassProjectile(SinglePolyTrailProjectile) {
    FxImpactTrajectoryAligned = false,
    FxTrails = EffectTemplate.AOblivionCannonFXTrails02,
    PolyTrail = EffectTemplate.Aeon_QuanticClusterProjectilePolyTrail,
    FxImpactUnit = EffectTemplate.AOblivionCannonHit02,
    FxImpactProp = EffectTemplate.AOblivionCannonHit02,
    FxImpactLand = EffectTemplate.AOblivionCannonHit02,
    FxImpactWater = EffectTemplate.AOblivionCannonHit02,
}

--- AEON OBLIVION PROJECILE
---@class AOblivionCannonProjectile03 : EmitterProjectile
AOblivionCannonProjectile03 = ClassProjectile(EmitterProjectile) {
    FxTrails = EffectTemplate.AOblivionCannonFXTrails03,
    FxImpactUnit = EffectTemplate.AOblivionCannonHit03,
    FxImpactProp = EffectTemplate.AOblivionCannonHit03,
    FxImpactLand = EffectTemplate.AOblivionCannonHit03,
    FxImpactWater = EffectTemplate.AOblivionCannonHit03,
}

--- AEON QUANTUM PROJECTILES
---@class AQuantumCannonProjectile : SinglePolyTrailProjectile
AQuantumCannonProjectile = ClassProjectile(SinglePolyTrailProjectile) {
    FxTrails = {
        '/effects/emitters/quantum_cannon_munition_03_emit.bp',
        '/effects/emitters/quantum_cannon_munition_04_emit.bp',
    },
    PolyTrail = '/effects/emitters/quantum_cannon_polytrail_01_emit.bp',
    FxImpactUnit = EffectTemplate.AQuantumDisruptorHit01,
    FxImpactProp = EffectTemplate.AQuantumDisruptorHit01,
    FxImpactLand = EffectTemplate.AQuantumDisruptorHit01,
    FxImpactWater = EffectTemplate.AQuantumDisruptorHitWater01,
    FxImpactWaterScale = 0.6,
}

--- AEON QUANTUM PROJECTILES
---@class AQuantumDisruptorProjectile : SinglePolyTrailProjectile
AQuantumDisruptorProjectile = ClassProjectile(SinglePolyTrailProjectile) { 
    PolyTrail = '/effects/emitters/default_polytrail_03_emit.bp',
    FxTrails = EffectTemplate.AQuantumDisruptor01,
    FxImpactUnit = EffectTemplate.AQuantumDisruptorHit01,
    FxImpactProp = EffectTemplate.AQuantumDisruptorHit01,
    FxImpactLand = EffectTemplate.AQuantumDisruptorHit01,
}

--- AEON AA PROJECTILES
---@class AAAQuantumDisplacementCannonProjectile : NullShell
AAAQuantumDisplacementCannonProjectile = ClassProjectile(NullShell) {
    PolyTrail = '/effects/emitters/quantum_displacement_cannon_polytrail_01_emit.bp',
    FxImpactUnit = EffectTemplate.AQuantumDisplacementHit01,
    FxImpactProp = EffectTemplate.AQuantumDisplacementHit01,
    FxImpactAirUnit = EffectTemplate.AQuantumDisplacementHit01,
    FxImpactLand = EffectTemplate.AQuantumDisplacementHit01,
    FxImpactNone = EffectTemplate.AQuantumDisplacementHit01,
    FxTeleport = EffectTemplate.AQuantumDisplacementTeleport01,
    FxInvisible = '/effects/emitters/sparks_08_emit.bp',

    ---@param self AAAQuantumDisplacementCannonProjectile
    OnCreate = function(self)
        NullShell.OnCreate(self)

        self.TrailEmitters = {}
        self:CreateTrailFX()
        self:ForkThread(self.UpdateThread)
    end,

    ---@param self AAAQuantumDisplacementCannonProjectile
    CreateTrailFX = function(self)
        if(self.PolyTrail) then
            table.insert(self.TrailEmitters, CreateTrail(self, -1, self.Army, self.PolyTrail))
        end
    end,

    ---@param self AAAQuantumDisplacementCannonProjectile
    ---@param army Army
    CreateTeleportFX = function(self, army)
        for i in self.FxTeleport do
            CreateEmitterAtEntity(self, army, self.FxTeleport[i])
        end
    end,

    ---@param self AAAQuantumDisplacementCannonProjectile
    DestroyTrailFX = function(self)
        if self.TrailEmitters then
            for k,v in self.TrailEmitters do
                v:Destroy()
                v = nil
            end
        end
    end,

    ---@param self AAAQuantumDisplacementCannonProjectile
    UpdateThread = function(self)
        WaitSeconds(0.3)
        self:DestroyTrailFX()
        self:CreateTeleportFX(self.Army)
        local emit = CreateEmitterOnEntity(self, self.Army, self.FxInvisible)
        WaitSeconds(0.45)
        emit:Destroy()
        self:CreateTeleportFX()
        self:CreateTrailFX()
    end,
}

--- AEON QUANTUM DISTORTION NUCLEAR WARHEAD PROJECTILES
---@class AQuantumWarheadProjectile : NukeProjectile
AQuantumWarheadProjectile = ClassProjectile(NukeProjectile, MultiCompositeEmitterProjectile) {
    Beams = {'/effects/emitters/aeon_nuke_exhaust_beam_01_emit.bp',},
    PolyTrails = {'/effects/emitters/aeon_nuke_trail_emit.bp',},
}

--- AEON QUARK BOMB
--- Strategic bomber
---@class AQuarkBombProjectile : EmitterProjectile
AQuarkBombProjectile = ClassProjectile(EmitterProjectile) { 
    FxTrails = EffectTemplate.AQuarkBomb01,
    FxTrailScale = 1,
    FxImpactUnit = EffectTemplate.AQuarkBombHitUnit01,
    FxImpactProp = EffectTemplate.AQuarkBombHitUnit01,
    FxImpactAirUnit = EffectTemplate.AQuarkBombHitAirUnit01,
    FxImpactLand = EffectTemplate.AQuarkBombHitLand01,

    ---@param self AQuarkBombProjectile
    ---@param targetType string
    ---@param targetEntity Prop|Unit
    OnImpact = function(self, targetType, targetEntity)
        EmitterProjectile.OnImpact(self, targetType, targetEntity)
        CreateLightParticle(self, -1, self.Army, 26, 6, 'sparkle_white_add_08', 'ramp_white_02')
    end,
}

---  AEON RAIL GUN PROJECTILES
---@class ARailGunProjectile : EmitterProjectile
ARailGunProjectile = ClassProjectile(EmitterProjectile) {
    FxTrails = {'/effects/emitters/railgun_munition_trail_02_emit.bp',
        '/effects/emitters/railgun_munition_trail_01_emit.bp'},
    FxTrailScale = 0,
    FxTrailOffset = 0,
}

--- AEON REACTON CANNON PROJECTILES
--- Support Command Unit
---@class AReactonCannonProjectile : EmitterProjectile
AReactonCannonProjectile = ClassProjectile(EmitterProjectile) {
    FxTrails = {
        '/effects/emitters/reacton_cannon_fxtrail_01_emit.bp',
        '/effects/emitters/reacton_cannon_fxtrail_02_emit.bp',
        '/effects/emitters/reacton_cannon_fxtrail_03_emit.bp',
    },
    FxImpactUnit = EffectTemplate.AReactonCannonHitUnit01,
    FxImpactProp = EffectTemplate.AReactonCannonHitUnit01,
    FxImpactLand = EffectTemplate.AReactonCannonHitLand01,
}

--- AEON REACTON CANNON PROJECTILES
---@class AReactonCannonAOEProjectile : EmitterProjectile
AReactonCannonAOEProjectile = ClassProjectile(EmitterProjectile) {
    FxTrails = {
        '/effects/emitters/reacton_cannon_fxtrail_01_emit.bp',
        '/effects/emitters/reacton_cannon_fxtrail_02_emit.bp',
        '/effects/emitters/reacton_cannon_fxtrail_03_emit.bp',
    },
    FxImpactUnit = EffectTemplate.AReactonCannonHitUnit01,
    FxImpactProp = EffectTemplate.AReactonCannonHitUnit01,
    FxImpactLand = EffectTemplate.AReactonCannonHitLand02,
}

--- AEON DISRUPTOR PROJECTILES
---@class ADisruptorProjectile : SinglePolyTrailProjectile
ADisruptorProjectile = ClassProjectile(SinglePolyTrailProjectile) {
    PolyTrail = '/effects/emitters/default_polytrail_03_emit.bp',
    FxTrails = EffectTemplate.ADisruptorMunition01,
    FxImpactUnit = EffectTemplate.ADisruptorHit01,
    FxImpactProp = EffectTemplate.ADisruptorHit01,
    FxImpactLand = EffectTemplate.ADisruptorHit01,
    FxImpactShield = EffectTemplate.ADisruptorHitShield,
}

--- AEON DISRUPTOR PROJECTILES
---@class AShieldDisruptorProjectile : SinglePolyTrailProjectile
AShieldDisruptorProjectile = ClassProjectile(SinglePolyTrailProjectile) {
    PolyTrail = EffectTemplate.ASDisruptorPolytrail01,
    FxTrails = EffectTemplate.ASDisruptorMunition01,
    FxImpactUnit = EffectTemplate.ASDisruptorHitUnit01,
    FxImpactProp = EffectTemplate.ASDisruptorHitUnit01,
    FxImpactLand = EffectTemplate.ASDisruptorHit01,
    FxImpactShield = EffectTemplate.ASDisruptorHitShield,
}

--- AEON ROCKET PROJECTILES
---@class ARocketProjectile : EmitterProjectile
ARocketProjectile = ClassProjectile(EmitterProjectile) {
    FxTrails = {'/effects/emitters/missile_sam_munition_trail_cybran_01_emit.bp',},
    FxTrailOffset = 0.5,
    FxImpactUnit = EffectTemplate.AMissileHit01,
    FxImpactProp = EffectTemplate.AMissileHit01,
    FxImpactLand = EffectTemplate.AMissileHit01,
}

--- AEON SONIC PULSE AA PROJECTILES
---@class ASonicPulseProjectile : SinglePolyTrailProjectile
ASonicPulseProjectile = ClassProjectile(SinglePolyTrailProjectile) {
    PolyTrail = '/effects/emitters/sonic_pulse_munition_polytrail_01_emit.bp',
    FxImpactAirUnit = EffectTemplate.ASonicPulseHitAirUnit01,
    FxImpactUnit = EffectTemplate.ASonicPulseHitUnit01,
    FxImpactProp = EffectTemplate.ASonicPulseHitUnit01,
    FxImpactLand = EffectTemplate.ASonicPulseHitLand01,
}

---## AEON SONIC PULSE AA PROJECTILES
--- Custom version of the sonic pulse battery projectile for flying units
---@class ASonicPulseProjectile02 : SinglePolyTrailProjectile
ASonicPulseProjectile02 = ClassProjectile(SinglePolyTrailProjectile) {
    PolyTrail = '/effects/emitters/sonic_pulse_munition_polytrail_02_emit.bp',
    FxImpactAirUnit = EffectTemplate.ASonicPulseHitAirUnit01,
    FxImpactUnit = EffectTemplate.ASonicPulseHitUnit01,
    FxImpactProp = EffectTemplate.ASonicPulseHitUnit01,
    FxImpactLand = EffectTemplate.ASonicPulseHitLand01,
}

--- AEON FIZZ LAUNCHER PROJECTILE
---@class ATemporalFizzAAProjectile : SingleCompositeEmitterProjectile
ATemporalFizzAAProjectile = ClassProjectile(SingleCompositeEmitterProjectile) {
    BeamName = '/effects/emitters/temporal_fizz_munition_beam_01_emit.bp',
    PolyTrail = '/effects/emitters/default_polytrail_03_emit.bp',
    FxImpactUnit = EffectTemplate.ATemporalFizzHit01,
    FxImpactAirUnit = EffectTemplate.ATemporalFizzHit01,
    FxImpactNone = EffectTemplate.ATemporalFizzHit01,
}

--- AEON ABOVE WATER LAUNCHED TORPEDO
---@class ATorpedoShipProjectile : OnWaterEntryEmitterProjectile
ATorpedoShipProjectile = ClassProjectile(OnWaterEntryEmitterProjectile) {
    FxTrails = {'/effects/emitters/torpedo_munition_trail_01_emit.bp',},
    FxTrailScale = 1,
    TrailDelay = 0,
    TrackTime = 0,
    FxUnitHitScale = 1.25,
    FxImpactUnit = EffectTemplate.ATorpedoUnitHit01,
    FxImpactProp = EffectTemplate.ATorpedoUnitHit01,
    FxImpactUnderWater = EffectTemplate.DefaultProjectileUnderWaterImpact,
    FxImpactProjectile = EffectTemplate.ATorpedoUnitHit01,
    FxImpactProjectileUnderWater = EffectTemplate.DefaultProjectileUnderWaterImpact,
    FxOnKilled = EffectTemplate.ATorpedoUnitHit01,

    ---@param self ATorpedoShipProjectile
    ---@param inWater boolean
    OnCreate = function(self,inWater)
        OnWaterEntryEmitterProjectile.OnCreate(self, inWater)
        -- if we are starting in the water then immediately switch to tracking in water
        if inWater == true then
            self:TrackTarget(true):StayUnderwater(true)
            self:OnEnterWater(self)
        else
            self:TrackTarget(false)
        end
    end,

    ---@param self ATorpedoShipProjectile
    OnEnterWater = function(self)
        OnWaterEntryEmitterProjectile.OnEnterWater(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)
    end,

}

--- AEON SUB LAUNCHED TORPEDO
---@class ATorpedoSubProjectile : EmitterProjectile
ATorpedoSubProjectile = ClassProjectile(EmitterProjectile) {
    FxTrails = {'/effects/emitters/torpedo_munition_trail_01_emit.bp',},
    FxUnitHitScale = 1.25,
    FxImpactUnit = EffectTemplate.ATorpedoUnitHit01,
    FxImpactProp = EffectTemplate.ATorpedoUnitHit01,
    FxImpactUnderWater = EffectTemplate.ATorpedoUnitHit01,
    FxImpactProjectileUnderWater = EffectTemplate.DefaultProjectileUnderWaterImpact,
    FxNoneHitScale = 1,
    OnCreate = function(self, inWater)
        self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)
        EmitterProjectile.OnCreate(self, inWater)
    end,
}

--- AEON SUB LAUNCHED TORPEDO
---@class QuasarAntiTorpedoChargeSubProjectile : MultiPolyTrailProjectile
QuasarAntiTorpedoChargeSubProjectile = ClassProjectile(MultiPolyTrailProjectile) {
    FxImpactLand = EffectTemplate.AQuasarAntiTorpedoHit,
    FxUnitHitScale = 1.25,
    FxImpactUnit = EffectTemplate.AQuasarAntiTorpedoHit,
    FxImpactProp = EffectTemplate.AQuasarAntiTorpedoHit,
    FxImpactUnderWater = EffectTemplate.AQuasarAntiTorpedoHit,
    FxImpactProjectileUnderWater = EffectTemplate.AQuasarAntiTorpedoHit,
    FxNoneHitScale = 1,
    FxImpactNone = EffectTemplate.AQuasarAntiTorpedoHit,
    PolyTrails= EffectTemplate.AQuasarAntiTorpedoPolyTrails,
    PolyTrailOffset = { 0, 0 },
}

--------------------------------------------------------------------------
--  SC1X PROJECTILES
--------------------------------------------------------------------------

--- SC1X AEON BASE TEMPRORARY PROJECTILE
---@class ABaseTempProjectile : SinglePolyTrailProjectile
ABaseTempProjectile = ClassProjectile(SinglePolyTrailProjectile) {
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

--- AEON QUANTUM AUTOGUN SHELL
---@class AQuantumAutogun : SinglePolyTrailProjectile
AQuantumAutogun = ClassProjectile(SinglePolyTrailProjectile) {
    FxImpactLand = EffectTemplate.Aeon_DualQuantumAutoGunHitLand,
    FxImpactNone = EffectTemplate.Aeon_DualQuantumAutoGunHit,
    FxImpactProp = EffectTemplate.Aeon_DualQuantumAutoGunHit_Unit,
    FxImpactWater = EffectTemplate.Aeon_DualQuantumAutoGunHitLand,
    FxImpactUnit = EffectTemplate.Aeon_DualQuantumAutoGunHit_Unit,
    PolyTrail = EffectTemplate.Aeon_DualQuantumAutoGunProjectileTrail,
    FxTrails = EffectTemplate.Aeon_DualQuantumAutoGunFxTrail,
}

--- AEON HEAVY DISRUPTOR CANNON SHELL
---@class AHeavyDisruptorCannonShell : MultiPolyTrailProjectile
AHeavyDisruptorCannonShell = ClassProjectile(MultiPolyTrailProjectile) {
    FxImpactLand = EffectTemplate.Aeon_HeavyDisruptorCannonLandHit,
    FxImpactNone = EffectTemplate.Aeon_HeavyDisruptorCannonLandHit,
    FxImpactProp = EffectTemplate.Aeon_HeavyDisruptorCannonLandHit,
    FxImpactUnit = EffectTemplate.Aeon_HeavyDisruptorCannonUnitHit,
    FxTrails = EffectTemplate.Aeon_HeavyDisruptorCannonProjectileFxTrails,
    PolyTrails = EffectTemplate.Aeon_HeavyDisruptorCannonProjectileTrails,
}

--- AEON TORPEDO CLUSTER
---@class ATorpedoCluster : ATorpedoShipProjectile
ATorpedoCluster = ClassProjectile(ATorpedoShipProjectile) {
    FxInitial = { },
    FxTrails = { },
    PolyTrail = '',
    FxTrailScale = 1,
    TrailDelay = 0,
    TrackTime = 0,
    FxUnitHitScale = 1.25,
    FxImpactUnit = EffectTemplate.ATorpedoUnitHit01,
    FxImpactProp = EffectTemplate.ATorpedoUnitHit01,
    FxImpactUnderWater = EffectTemplate.ATorpedoUnitHitUnderWater01,
    FxImpactProjectile = EffectTemplate.ATorpedoUnitHit01,
    FxImpactProjectileUnderWater = EffectTemplate.ATorpedoUnitHitUnderWater01,
    FxOnKilled = EffectTemplate.ATorpedoUnitHit01,
}

--- AEON QUANTUM CLUSTER
---@class AQuantumCluster : ABaseTempProjectile
AQuantumCluster = ClassProjectile(ABaseTempProjectile) {}

--- AEON LIGHT DISPLACEMENT AUTOCANNON
---@class ALightDisplacementAutoCannon : ABaseTempProjectile
ALightDisplacementAutoCannon = ClassProjectile(ABaseTempProjectile) {}

--- AEON ARTILLERY FRAGMENTATION SENSOR SHELL
---@class AArtilleryFragmentationSensorShellProjectile : SinglePolyTrailProjectile
AArtilleryFragmentationSensorShellProjectile = ClassProjectile(SinglePolyTrailProjectile) {
    FxTrails = EffectTemplate.Aeon_QuanticClusterProjectileTrails,
    PolyTrail = EffectTemplate.Aeon_QuanticClusterProjectilePolyTrail,
    FxImpactLand = EffectTemplate.Aeon_QuanticClusterHit,
    FxLandHitScale = 0.5,
}

--- AEON ARTILLERY FRAGMENTATION SENSOR SHELL 02 (split 1)
---@class AArtilleryFragmentationSensorShellProjectile02 : AArtilleryFragmentationSensorShellProjectile
AArtilleryFragmentationSensorShellProjectile02 = ClassProjectile(AArtilleryFragmentationSensorShellProjectile) {
    FxTrails = EffectTemplate.Aeon_QuanticClusterProjectileTrails02,
    PolyTrail = EffectTemplate.Aeon_QuanticClusterProjectilePolyTrail02,
}

--- AEON ARTILLERY FRAGMENTATION SENSOR SHELL 03 (split 2)
---@class AArtilleryFragmentationSensorShellProjectile03 : AArtilleryFragmentationSensorShellProjectile
AArtilleryFragmentationSensorShellProjectile03 = ClassProjectile(AArtilleryFragmentationSensorShellProjectile) {
    PolyTrail = EffectTemplate.Aeon_QuanticClusterProjectilePolyTrail03,
    FxTrails = { },
}

-- kept for mod backwards compatibility
local DefaultExplosion = import("/lua/defaultexplosions.lua")
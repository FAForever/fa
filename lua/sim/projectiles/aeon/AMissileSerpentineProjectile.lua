
--**********************************************************************************
--** Copyright (c) 2023 FAForever
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--**********************************************************************************

local EffectTemplate = import("/lua/effecttemplates.lua")
local SingleCompositeEmitterProjectile = import("/lua/sim/defaultprojectiles.lua").SingleCompositeEmitterProjectile
local SingleCompositeEmitterProjectileOnCreate = SingleCompositeEmitterProjectile.OnCreate
local SingleCompositeEmitterProjectileOnKilled = SingleCompositeEmitterProjectile.OnKilled
local SingleCompositeEmitterProjectileOnImpact = SingleCompositeEmitterProjectile.OnImpact
local SingleCompositeEmitterProjectileOnExitwater = SingleCompositeEmitterProjectile.OnExitWater

local DebrisComponent = import('/lua/sim/projectiles/components/DebrisComponent.lua').DebrisComponent
local TacticalMissileComponent = import('/lua/sim/defaultprojectiles.lua').TacticalMissileComponent

--- AEON SERPENTINE MISSILE PROJECTILES
---@class AMissileSerpentineProjectile : SingleCompositeEmitterProjectile, TacticalMissileComponent, DebrisComponent
AMissileSerpentineProjectile = ClassProjectile(SingleCompositeEmitterProjectile, TacticalMissileComponent,
    DebrisComponent) {
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

    DebrisBlueprints = {
        '/effects/Entities/TacticalDebris01/TacticalDebris01_proj.bp',
        '/effects/Entities/TacticalDebris01/TacticalDebris01_proj.bp',
        '/effects/Entities/TacticalDebris02/TacticalDebris02_proj.bp',
    },

    ---@param self AMissileSerpentineProjectile
    OnCreate = function(self)
        SingleCompositeEmitterProjectileOnCreate(self)
        local blueprintPhysics = self.Blueprint.Physics
        local radius = 0.105 * (blueprintPhysics.MaxSpeed + blueprintPhysics.MaxSpeedRange)
        self:SetCollisionShape('Sphere', 0, 0, 0, radius)
    end,

    ---@param self AMissileSerpentineProjectile
    ---@param instigator Unit
    ---@param type string
    ---@param overkillRatio number
    OnKilled = function(self, instigator, type, overkillRatio)
        SingleCompositeEmitterProjectileOnKilled(self, instigator, type, overkillRatio)

        self:CreateDebris()
        CreateLightParticle(self, -1, self.Army, 3, 6, 'flare_lens_add_02', 'ramp_aeon_02')
    end,

    ---@param self AMissileSerpentineProjectile
    ---@param targetType string
    ---@param targetEntity Prop|Unit
    OnImpact = function(self, targetType, targetEntity)
        SingleCompositeEmitterProjectileOnImpact(self, targetType, targetEntity)
        if targetType == 'None' or targetType == 'Air' then
            self:CreateDebris()
        end

        CreateLightParticle(self, -1, self.Army, 4, 4, 'flare_lens_add_02', 'ramp_aeon_02')
    end,

    ---@param self AMissileSerpentineProjectile
    OnExitWater = function(self)
        SingleCompositeEmitterProjectileOnExitwater(self)
        self:SetDestroyOnWater(true)
    end,
}

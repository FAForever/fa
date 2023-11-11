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
local DebrisComponent = import('/lua/sim/projectiles/components/DebrisComponent.lua').DebrisComponent
local TacticalMissileComponent = import('/lua/sim/defaultprojectiles.lua').TacticalMissileComponent

local SingleBeamProjectile = import("/lua/sim/defaultprojectiles.lua").SingleBeamProjectile
local SingleBeamProjectileOnCreate = SingleBeamProjectile.OnCreate
local SingleBeamProjectileOnKilled = SingleBeamProjectile.OnKilled
local SingleBeamProjectileOnImpact = SingleBeamProjectile.OnImpact

local CreateLightParticle = CreateLightParticle

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
        SingleBeamProjectileOnCreate(self)
        local blueprintPhysics = self.Blueprint.Physics
        local radius = 0.105 * (blueprintPhysics.MaxSpeed + blueprintPhysics.MaxSpeedRange)
        self:SetCollisionShape('Sphere', 0, 0, 0, radius)
    end,

    ---@param self TMissileProjectile
    ---@param instigator Unit
    ---@param type string
    ---@param overkillRatio number
    OnKilled = function(self, instigator, type, overkillRatio)
        SingleBeamProjectileOnKilled(self, instigator, type, overkillRatio)

        self:CreateDebris()
        CreateLightParticle(self, -1, self.Army, 3, 6, 'flare_lens_add_02', 'ramp_fire_13')
    end,

    ---@param self TMissileProjectile
    ---@param targetType string
    ---@param targetEntity Prop|Unit
    OnImpact = function(self, targetType, targetEntity)
        SingleBeamProjectileOnImpact(self, targetType, targetEntity)
        if targetType == 'None' or targetType == 'Air' then
            self:CreateDebris()
        end

        CreateLightParticle(self, -1, self.Army, 4, 4, 'flare_lens_add_02', 'ramp_fire_13')
    end,
}

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

local SinglePolyTrailProjectile = import('/lua/sim/defaultprojectiles.lua').SinglePolyTrailProjectile
local EffectTemplate = import('/lua/effecttemplates.lua')

---  SERAPHIM LAANSE TACTICAL MISSILE
--- ACU / SACU / TML / MML
---@class SLaanseTacticalMissile : SinglePolyTrailProjectile
SLaanseTacticalMissile = ClassProjectile(SinglePolyTrailProjectile) {
    FxImpactLand = EffectTemplate.SLaanseMissleHit,
    FxImpactWater = EffectTemplate.SLaanseMissleHitWater,
    FxImpactProp = EffectTemplate.SLaanseMissleHitUnit,
    FxImpactUnit = EffectTemplate.SLaanseMissleHitUnit,
    FxImpactAirUnit = EffectTemplate.SLaanseMissleHitUnit,

    FxOnKilled = EffectTemplate.SLaanseMissleHitNone,
    FxOnKilledScale = 0.6,

    FxImpactNone = EffectTemplate.SLaanseMissleHitNone,
    FxNoneHitScale = 0.6,

    FxTrails = EffectTemplate.SLaanseMissleExhaust02,
    PolyTrail = EffectTemplate.SLaanseMissleExhaust01,

    ---@param self SLaanseTacticalMissile
    OnCreate = function(self)
        SinglePolyTrailProjectile.OnCreate(self)
        local blueprintPhysics = self.Blueprint.Physics
        local radius = 0.105 * (blueprintPhysics.MaxSpeed + blueprintPhysics.MaxSpeedRange)
        self:SetCollisionShape('Sphere', 0, 0, 0, radius)
    end,

    ---@param self SLaanseTacticalMissile
    ---@param instigator Unit
    ---@param type string
    ---@param overkillRatio number
    OnKilled = function(self, instigator, type, overkillRatio)
        SinglePolyTrailProjectile.OnKilled(self, instigator, type, overkillRatio)
        CreateLightParticle(self, -1, self.Army, 3, 6, 'flare_lens_add_02', 'ramp_blue_13')
    end,

    ---@param self SLaanseTacticalMissile
    ---@param targetType string
    ---@param targetEntity Prop|Unit
    OnImpact = function(self, targetType, targetEntity)
        SinglePolyTrailProjectile.OnImpact(self, targetType, targetEntity)
        CreateLightParticle(self, -1, self.Army, 4, 4, 'flare_lens_add_02', 'ramp_blue_13')
    end,
}
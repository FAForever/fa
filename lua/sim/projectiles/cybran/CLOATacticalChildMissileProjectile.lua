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
local SingleBeamProjectile = import('/lua/sim/defaultprojectiles.lua').SingleBeamProjectile
local TacticalMissileComponent = import('/lua/sim/DefaultWeapons.lua').TacticalMissileComponent

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
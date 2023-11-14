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
local TacticalMissileComponent = import('/lua/terranprojectiles.lua').TacticalMissileComponent

---  CYBRAN ROCKET PROJECILES
---@class CLOATacticalMissileProjectile : SingleBeamProjectile, TacticalMissileComponent, SplitComponent, DebrisComponent
---@field SplitDamage { DamageAmount: number, DamageRadius: number }
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
    ---@param instigator Unit
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
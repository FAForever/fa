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
local OnWaterEntryEmitterProjectile = import('/lua/sim/OnWaterEntryEmitterProjectile.lua').OnWaterEntryEmitterProjectile

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
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
local OnWaterEntryEmitterProjectile = import("/lua/sim/defaultprojectiles.lua").OnWaterEntryEmitterProjectile
local OnWaterEntryEmitterProjectileOnCreate = OnWaterEntryEmitterProjectile.OnCreate

--- AEON DEPTH CHARGE
---@class ADepthChargeProjectile : OnWaterEntryEmitterProjectile
ADepthChargeProjectile = ClassProjectile(OnWaterEntryEmitterProjectile) {
    FxTrails = { '/effects/emitters/torpedo_munition_trail_01_emit.bp', },
    TrailDelay = 0,
    TrackTime = 0,
    FxImpactUnit = EffectTemplate.ADepthChargeHitUnit01,
    FxImpactProp = EffectTemplate.ADepthChargeHitUnit01,
    FxImpactUnderWater = EffectTemplate.ADepthChargeHitUnderWaterUnit01,

    OnEnterWater = function(self)
        OnWaterEntryEmitterProjectileOnCreate(self)
        self:SetMaxSpeed(20)
        self:SetAcceleration(5)
        self:SetTurnRate(180)
        self:SetVelocity(0.5)
    end,
}

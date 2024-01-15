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
local OnWaterEntryEmitterProjectileOnEnterWater = OnWaterEntryEmitterProjectile.OnEnterWater

---  TERRAN DEPTH CHARGE PROJECTILES
---@class TDepthChargeProjectile : OnWaterEntryEmitterProjectile
TDepthChargeProjectile = ClassProjectile(OnWaterEntryEmitterProjectile) {
    FxTrails = { '/effects/emitters/torpedo_underwater_wake_01_emit.bp', },
    TrailDelay = 0,
    FxUnitHitScale = 1.25,
    FxImpactUnit = EffectTemplate.TTorpedoHitUnit01,
    FxImpactProp = EffectTemplate.TTorpedoHitUnit01,
    FxImpactUnderWater = EffectTemplate.TTorpedoHitUnit01,
    FxImpactProjectile = EffectTemplate.TTorpedoHitUnit01,
    FxEnterWater = EffectTemplate.WaterSplash01,

    ---@param self TDepthChargeProjectile
    ---@param inWater? boolean
    OnCreate = function(self, inWater)
        OnWaterEntryEmitterProjectileOnCreate(self)
        self:TrackTarget(false)
    end,

    ---@param self TDepthChargeProjectile
    OnEnterWater = function(self)
        OnWaterEntryEmitterProjectileOnEnterWater(self)
        self:TrackTarget(false)
        self:StayUnderwater(true)
    end,
}

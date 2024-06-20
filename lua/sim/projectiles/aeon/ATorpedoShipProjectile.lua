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

--- AEON ABOVE WATER LAUNCHED TORPEDO
---@class ATorpedoShipProjectile : OnWaterEntryEmitterProjectile
ATorpedoShipProjectile = ClassProjectile(OnWaterEntryEmitterProjectile) {
    FxTrails = { '/effects/emitters/torpedo_munition_trail_01_emit.bp', },
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
    OnCreate = function(self, inWater)
        OnWaterEntryEmitterProjectileOnCreate(self, inWater)
        -- if we are starting in the water then immediately switch to tracking in water
        if inWater == true then
            self:TrackTarget(true)
            self:StayUnderwater(true)
            self:OnEnterWater(self)
        else
            self:TrackTarget(false)
        end
    end,

    ---@param self ATorpedoShipProjectile
    OnEnterWater = function(self)
        OnWaterEntryEmitterProjectileOnEnterWater(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)
    end,
}

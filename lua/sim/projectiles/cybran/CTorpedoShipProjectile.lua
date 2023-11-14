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

local OnWaterEntryEmitterProjectile = import('/lua/sim/defaultprojectiles.lua').OnWaterEntryEmitterProjectile
local EffectTemplate = import("/lua/effecttemplates.lua")

---  CYBRAN ABOVE WATER LAUNCHED TORPEDO
---@class CTorpedoShipProjectile : OnWaterEntryEmitterProjectile
CTorpedoShipProjectile = ClassProjectile(OnWaterEntryEmitterProjectile) {
    FxSplashScale = 0.5,
    FxTrails = {'/effects/emitters/torpedo_munition_trail_01_emit.bp',},
    FxTrailScale = 1.25,
    FxTrailOffset = 0.2,
    FxEnterWater= { '/effects/emitters/water_splash_ripples_ring_01_emit.bp',
                    '/effects/emitters/water_splash_plume_01_emit.bp',
    },
    FxUnitHitScale = 1.25,
    FxImpactUnit = EffectTemplate.CTorpedoUnitHit01,
    FxImpactProp = EffectTemplate.CTorpedoUnitHit01,
    FxImpactUnderWater = EffectTemplate.CTorpedoUnitHit01,

    --- if we are starting in the water then immediately switch to tracking in water
    ---@param self CTorpedoShipProjectile
    ---@param inWater boolean
    OnCreate = function(self, inWater)
        OnWaterEntryEmitterProjectile.OnCreate(self, inWater)

        if inWater == true then
            self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)
        end
    end,

    ---@param self CTorpedoShipProjectile
    OnEnterWater = function(self)
        OnWaterEntryEmitterProjectile.OnEnterWater(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)
    end,
}
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

local EmitterProjectile = import('/lua/sim/defaultprojectiles.lua').EmitterProjectile
local EffectTemplate = import("/lua/effecttemplates.lua")

---  CYBRAN SUB LAUNCHED TORPEDO
---@class CTorpedoSubProjectile : EmitterProjectile
CTorpedoSubProjectile = ClassProjectile(EmitterProjectile) {
    FxTrails = {'/effects/emitters/torpedo_underwater_wake_02_emit.bp',},
    FxUnitHitScale = 1.25,
    FxImpactUnit = EffectTemplate.CTorpedoUnitHit01,
    FxImpactProp = EffectTemplate.CTorpedoUnitHit01,
    FxImpactUnderWater = EffectTemplate.CTorpedoUnitHit01,
    FxImpactLand = EffectTemplate.CTorpedoUnitHit01,
    FxLandHitScale = 0.25,
    FxNoneHitScale = 1,

    ---@param self CTorpedoSubProjectile
    ---@param inWater boolean
    OnCreate = function(self, inWater)
        self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)
        EmitterProjectile.OnCreate(self, inWater)
    end,
}
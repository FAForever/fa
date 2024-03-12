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

local SingleCompositeEmitterProjectile = import('/lua/sim/defaultprojectiles.lua').SingleCompositeEmitterProjectile
local EffectTemplate = import("/lua/effecttemplates.lua")
local SingleBeamProjectile = import('/lua/sim/defaultprojectiles.lua').SingleBeamProjectile

---  CYBRAN AA MISSILE PROJECILES - Air Targets
---@class CMissileAAProjectile : SingleCompositeEmitterProjectile
CMissileAAProjectile = ClassProjectile(SingleCompositeEmitterProjectile) {
    TrailDelay = 1,
    FxTrails = {'/effects/emitters/missile_sam_munition_trail_01_emit.bp',},
    FxTrailOffset = 0.5,
    BeamName = '/effects/emitters/missile_sam_munition_exhaust_beam_01_emit.bp',
    FxUnitHitScale = 0.5,
    FxImpactUnit = EffectTemplate.CMissileHit01,
    FxImpactProp = EffectTemplate.CMissileHit01,
    FxLandHitScale = 0.5,
    FxImpactLand = EffectTemplate.CMissileHit01,

    OnCreate = function(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)
        SingleBeamProjectile.OnCreate(self)
    end,
}
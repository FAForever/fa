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
local EffectTemplate = import("/lua/effecttemplates.lua")
local EmitterProjectile = import('/lua/sim/defaultprojectiles.lua').EmitterProjectile

---  CYBRAN ARTILLERY PROJECILES
---@class CArtilleryProtonProjectile : SinglePolyTrailProjectile
CArtilleryProtonProjectile = ClassProjectile(SinglePolyTrailProjectile) {
    FxImpactTrajectoryAligned = false,
    PolyTrail = '/effects/emitters/default_polytrail_01_emit.bp',
    FxImpactUnit = EffectTemplate.CProtonArtilleryHit01,
    FxImpactProp = EffectTemplate.CProtonArtilleryHit01,
    FxImpactLand = EffectTemplate.CProtonArtilleryHit01,

    ---@param self CArtilleryProtonProjectile
    ---@param targetType string
    ---@param targetEntity Unit
    OnImpact = function(self, targetType, targetEntity)
        EmitterProjectile.OnImpact(self, targetType, targetEntity)
        CreateLightParticle( self, -1, self.Army, 7, 12, 'glow_03', 'ramp_red_06' )
        CreateLightParticle( self, -1, self.Army, 7, 22, 'glow_03', 'ramp_antimatter_02' )
    end,
}
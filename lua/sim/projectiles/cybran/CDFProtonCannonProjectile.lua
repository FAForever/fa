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
local MultiPolyTrailProjectile = import("/lua/sim/defaultprojectiles.lua").MultiPolyTrailProjectile

---  CYBRAN PROTON PROJECTILES
---@class CDFProtonCannonProjectile : MultiPolyTrailProjectile
CDFProtonCannonProjectile = ClassProjectile(MultiPolyTrailProjectile) {
    PolyTrails = {
        EffectTemplate.CProtonCannonPolyTrail,
        '/effects/emitters/default_polytrail_01_emit.bp',
    },
    PolyTrailOffset = { 0, 0 },
    FxTrails = EffectTemplate.CProtonCannonFXTrail01,
    FxImpactUnit = EffectTemplate.CProtonCannonHit01,
    FxImpactProp = EffectTemplate.CProtonCannonHit01,
    FxImpactLand = EffectTemplate.CProtonCannonHit01,
    FxImpactWater = EffectTemplate.CProtonCannonHitWater01,
    FxImpactWaterScale = 0.75,
    FxTrailOffset = 0,
}
--******************************************************************************************************
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
--******************************************************************************************************

local AArtilleryProjectile = import("/lua/aeonprojectiles.lua").AArtilleryProjectile
local AArtilleryProjectileOnImpact = AArtilleryProjectile.OnImpact

local EffectTemplate = import("/lua/effecttemplates.lua")

--- Aeon T3 Mobile Artillery Projectile : ual0304
---@class AIFSonanceShell01 : AArtilleryProjectile
AIFSonanceShell01 = ClassProjectile(AArtilleryProjectile) {

    PolyTrail = '/effects/emitters/aeon_sonicgun_trail_emit.bp',
    FxTrails = EffectTemplate.ASonanceWeaponFXTrail01,
    FxImpactUnit =  EffectTemplate.ASonanceWeaponHit02,
    FxImpactProp =  EffectTemplate.ASonanceWeaponHit02,
    FxImpactLand =  EffectTemplate.ASonanceWeaponHit02,

    ---@param self AIFSonanceShell01
    ---@param targetType string
    ---@param targetEntity Prop|Unit
    OnImpact = function(self, targetType, targetEntity)
        AArtilleryProjectileOnImpact(self, targetType, targetEntity)

        -- our favorite shake: the camera shake
        self:ShakeCamera( 20, 1, 0, 1 )
    end,
}
TypeClass = AIFSonanceShell01
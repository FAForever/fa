--******************************************************************************************************
--** Copyright (c) 2022  Willem 'Jip' Wijnia
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


local Projectile = import("/lua/sim/projectile.lua").Projectile

local ProjectileOnCreate = Projectile.OnCreate

-- upvalue scope for performance
local CreateEmitterOnEntity = CreateEmitterOnEntity
local IEffectScaleEmitter = _G.moho.IEffect.ScaleEmitter
local IEffectOffsetEmitter = _G.moho.IEffect.OffsetEmitter

---@class EmitterProjectile : Projectile
EmitterProjectile = ClassProjectile(Projectile) {
    FxTrails = { '/effects/emitters/missile_munition_trail_01_emit.bp', },
    FxTrailScale = 1,
    FxTrailOffset = 0,

    ---@param self EmitterProjectile
    OnCreate = function(self)
        ProjectileOnCreate(self)

        local army = self.Army
        local fxTrails = self.FxTrails
        local fxTrailScale = self.FxTrailScale
        local fxTrailOffset = self.FxTrailOffset

        for i in fxTrails do
            local effect = CreateEmitterOnEntity(self, army, fxTrails[i])
            IEffectScaleEmitter(effect, fxTrailScale)
            IEffectOffsetEmitter(effect, 0, 0, fxTrailOffset)
        end
    end,
}

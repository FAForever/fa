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

-- upvalue scope for performance
local CreateEmitterOnEntity = CreateEmitterOnEntity
local IEffectScaleEmitter = _G.moho.IEffect.ScaleEmitter
local IEffectOffsetEmitter = _G.moho.IEffect.OffsetEmitter

---@class EmitterProjectile : Projectile
EmitterProjectile = ClassProjectile(Projectile) {
    FxTrails = {'/effects/emitters/missile_munition_trail_01_emit.bp',},
    FxTrailScale = 1,
    FxTrailOffset = 0,

    ---@param self EmitterProjectile
    OnCreate = function(self)
        Projectile.OnCreate(self)

        local fxTrailScale = self.FxTrailScale
        local fxTrailOffset = self.FxTrailOffset
        local army = self.Army

        local effect
        for i in self.FxTrails do
            effect = CreateEmitterOnEntity(self, army, self.FxTrails[i])

            if fxTrailScale ~= 1 then
                IEffectScaleEmitter(effect, fxTrailScale)
            end

            if fxTrailOffset ~= 1 then
                IEffectOffsetEmitter(effect, 0, 0, fxTrailOffset)
            end
        end
    end,
}

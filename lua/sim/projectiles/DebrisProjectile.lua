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

local DummyProjectile = import("/lua/sim/projectile.lua").DummyProjectile

-- upvalue for performance
local Random = Random
local CreateEmitterOnEntity = CreateEmitterOnEntity
local IEffectScaleEmitter = _G.moho.IEffect.ScaleEmitter

---@class BaseGenericDebris : DummyProjectile
BaseGenericDebris = ClassDummyProjectile(DummyProjectile) {

    FxImpactLand = import("/lua/effecttemplates.lua").GenericDebrisLandImpact01,
    FxImpactWater = import("/lua/effecttemplates.lua").WaterSplash01,
    FxTrails = import("/lua/effecttemplates.lua").GenericDebrisTrails01,

    ---@param self BaseGenericDebris
    OnCreate = function(self)
        DummyProjectile.OnCreate(self)

        local army = self.Army
        for k, effect in self.FxTrails do
            CreateEmitterOnEntity(self, army, effect)
        end
    end,

    ---@param self BaseGenericDebris
    ---@param targetType string
    ---@param targetEntity Unit | Shield | Projectile
    OnImpact = function(self, targetType, targetEntity)
        local army = self.Army

        -- default impact effect for land
        if targetType == 'Terrain' then
            for _, fxBlueprint in self.FxImpactLand do
                local effect = CreateEmitterAtEntity(self, army, fxBlueprint)
                IEffectScaleEmitter(effect, 0.05 + 0.15 * Random())
            end
        -- default impact for water
        elseif targetType == 'Water' then
            for _, fxBlueprint in self.FxImpactWater do
                local effect = CreateEmitterAtEntity(self, army, fxBlueprint)
                IEffectScaleEmitter(effect, 0.4 + 0.4 * Random())
            end
        end

        self:Destroy()
    end,
}

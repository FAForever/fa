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

local AReactonCannonProjectile = import("/lua/aeonprojectiles.lua").AReactonCannonProjectile
local AReactonCannonProjectileCreateImpactEffects = AReactonCannonProjectile.CreateImpactEffects

--- Aeon Reacton Cannon Area of Effect Projectile
---@class ADFReactonCannon01 : AReactonCannonProjectile
ADFReactonCannon01 = ClassProjectile(AReactonCannonProjectile) {

    ---@param self ADFReactonCannon01
    ---@param army number
    ---@param EffectTable table
    ---@param EffectScale number
    CreateImpactEffects = function(self, army, EffectTable, EffectScale)
        AReactonCannonProjectileCreateImpactEffects(self, army, EffectTable, EffectScale)

        local launcher = self.Launcher
        if launcher and launcher:HasEnhancement('StabilitySuppressant') then
            local army = self.Army
            CreateLightParticle(self, -1, army, 3.0, 6, 'ring_05', 'ramp_green_02')
            CreateEmitterAtEntity(self, army, '/effects/emitters/oblivion_cannon_hit_11_emit.bp')
        end
    end,
}
TypeClass = ADFReactonCannon01

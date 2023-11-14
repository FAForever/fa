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

local NullShell = import('/lua/sim/defaultprojectiles.lua').NullShell
local EffectTemplate = import("/lua/effecttemplates.lua")

--- CYBRAN PROTON PROJECTILES
--- T3 strategic bomber
---@class CIFProtonBombProjectile : NullShell
CIFProtonBombProjectile = ClassProjectile(NullShell) {
    FxImpactTrajectoryAligned = false,
    FxImpactUnit = EffectTemplate.CProtonBombHit01,
    FxImpactProp = EffectTemplate.CProtonBombHit01,
    FxImpactLand = EffectTemplate.CProtonBombHit01,

    ---@param self CIFProtonBombProjectile
    ---@param targetType string
    ---@param targetEntity Unit
    OnImpact = function(self, targetType, targetEntity)
        CreateLightParticle(self, -1, self.Army, 12, 28, 'glow_03', 'ramp_proton_flash_02')
        CreateLightParticle(self, -1, self.Army, 8, 22, 'glow_03', 'ramp_antimatter_02')

        local blanketSides = 12
        local blanketAngle = (2*math.pi) / blanketSides
        local blanketVelocity = 6.25
        for i = 0, (blanketSides-1) do
            local blanketX = math.sin(i*blanketAngle)
            local blanketZ = math.cos(i*blanketAngle)
            self:CreateProjectile('/effects/entities/EffectProtonAmbient01/EffectProtonAmbient01_proj.bp', blanketX, 0.5, blanketZ, blanketX, 0, blanketZ):SetVelocity(blanketVelocity):SetAcceleration(-0.3)
        end
        NullShell.OnImpact(self, targetType, targetEntity)
    end,
}
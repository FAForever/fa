
--**********************************************************************************
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
--**********************************************************************************

local MathSin = math.sin
local MathCos = math.cos
local MathPi = math.pi

---@class SplitComponent
SplitComponent = ClassSimple {

    ChildCount = 3,
    ChildProjectileBlueprint = '/projectiles/CIFMissileTacticalSplit01/CIFMissileTacticalSplit01_proj.bp',

    SpreadCone = 2 * MathPi,
    SpreadMultiplier = 1.0,
    SpreadMultiplierRange = 1.0,

    ---@param self SplitComponent | Projectile
    OnSplit = function(self, inheritTargetGround)
        local vx, vy, vz = self:GetVelocity()

        local spreadCone = self.SpreadCone
        local spreadMultiplier = self.SpreadMultiplier
        local spreadMultiplierRange = self.SpreadMultiplierRange

        local childCount = self.ChildCount
        local childBlueprint = self.ChildProjectileBlueprint
        local childVelocity = self:GetCurrentSpeed() * 5

        local childConeSection = spreadCone / childCount

        for i = 0, childCount - 1 do
            local xVec = vx + MathSin(i * childConeSection) * spreadMultiplier +
                (2 * spreadMultiplierRange * (Random() - 0.5))
            local yVec = vy + MathCos(i * childConeSection) * spreadMultiplier +
                (2 * spreadMultiplierRange * (Random() - 0.5))
            local zVec = vz + MathCos(i * childConeSection) * spreadMultiplier +
                (2 * spreadMultiplierRange * (Random() - 0.5))
            local proj = self:CreateChildProjectile(childBlueprint)
            -- proj:SetVelocity(xVec, yVec, zVec)
            -- proj:SetVelocity(childVelocity)
            proj.DamageData = self.DamageData

            if inheritTargetGround then
                proj:SetTurnRate(40)
                proj:SetNewTargetGround(self:GetCurrentTargetPosition())
                proj:TrackTarget(false)
            end
        end
    end,

}

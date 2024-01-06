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

---@class SplitComponent
SplitComponent = ClassSimple {

    ChildCount = 3,
    ChildProjectileBlueprint = '/projectiles/CIFMissileTacticalSplit01/CIFMissileTacticalSplit01_proj.bp',

    SpreadCone = 2 * MathPi,
    SpreadMultiplier = 0.5,
    SpreadMultiplierRange = 0,

    RotateOffsetDeg = 0,
    RotateOffsetRange = 60,
    ChildRotateOffsetRange = 40,

    ---@param self SplitComponent | Projectile
    OnSplit = function(self, inheritTargetGround)
        local childCount = self.ChildCount
        local childBlueprint = self.ChildProjectileBlueprint
        local spreadCone = self.SpreadCone
        local spreadMultiplier = self.SpreadMultiplier
        local spreadMultiplierRange = self.SpreadMultiplierRange
        
        local rotateOffsetRadRandom = (self.RotateOffsetDeg + (Random() - 0.5) * self.RotateOffsetRange) * MathPi / 180
        local childRotateOffsetRange = self.ChildRotateOffsetRange * MathPi / 180

        local childConeSection = spreadCone / childCount

        local vx, vy, vz = self:GetVelocity()
        local speed = self:GetCurrentSpeed()
        local wx, wy, wz = vx/speed, vy/speed, vz/speed


        for i = 0, childCount - 1 do
            local a = i * childConeSection + rotateOffsetRadRandom + (Random() - 0.5) * childRotateOffsetRange

            local cosA = MathCos(a)
            local sinA = MathSin(a)

            -- Rotation into forwards-facing circle
            -- Simplified from Y-axis rotation followed by 90 degree axis-angle rotation on the axis
            -- perpendicular to Y-axis and the velocity vector
            local dot = -wz * wz * sinA - wx * wx * sinA
            local xVec = -wx * wy + -wz * dot
            local yVec = wx * wx * cosA + wz * wz * cosA
            local zVec = -wz * wy + wx * dot
            local proj = self:CreateChildProjectile(childBlueprint)

            local spreadRandom = spreadMultiplier + (Random() - 0.5) * spreadMultiplierRange
            local complement = 1 - spreadRandom
            -- Set the direction of the projectile
            proj:SetVelocity(wx * complement + spreadRandom * xVec,
                             wy * complement + spreadRandom * yVec,
                             wz * complement + spreadRandom * zVec)
            -- GetCurrentSpeed() and GetVelocity() return in units of distance/tick,
            -- but SetVelocity(speed) expects units of distance/second, so we multiply by 10.
            proj:SetVelocity(speed*10)  
            proj.DamageData = self.DamageData

            if inheritTargetGround then
                proj:SetNewTargetGround(self:GetCurrentTargetPosition())
            end     

--         for k = 1, childCount do
--             local childProjectile = self:CreateChildProjectile(childBlueprint)
--             childProjectile.DamageData = self.DamageData

--             if inheritTargetGround then
--                 childProjectile:SetTurnRate(40)
--                 childProjectile:SetNewTargetGround(self:GetCurrentTargetPosition())
--                 childProjectile:TrackTarget(false)
--             end

--             childProjectile.Trash:Add(ForkThread(self.ZigZagThread, self, childProjectile))
--         end
--     end,
        end
    end,
    
--     --- Zig-zag the projectile to create some diversity
--     ---@param self SplitComponent | Projectile
--     ---@param childProjectile Projectile
--     ZigZagThread = function(self, childProjectile)
--         childProjectile:ChangeMaxZigZag(10)

--         -- we need this or the zigzag does not work
--         childProjectile:TrackTarget(true)

--         WaitTicks(9)

--         for k = 9, 1, -1 do
--             if not IsDestroyed(childProjectile) then
--                 childProjectile:ChangeMaxZigZag(k)
--                 childProjectile:ChangeZigZagFrequency(0.1 * k)
--             end

--             WaitTicks(3)
--         end

--         if not IsDestroyed(childProjectile) then
--             childProjectile:ChangeMaxZigZag(0.5)
--             childProjectile:ChangeZigZagFrequency(1)

}

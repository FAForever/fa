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

-- upvalue scope for performance
local ForkThread = ForkThread

---@class SplitComponent
SplitComponent = ClassSimple {

    ChildCount = 3,
    ChildProjectileBlueprint = '/projectiles/CIFMissileTacticalSplit01/CIFMissileTacticalSplit01_proj.bp',

    ---@param self SplitComponent | Projectile
    OnSplit = function(self, inheritTargetGround)
        local childCount = self.ChildCount
        local childBlueprint = self.ChildProjectileBlueprint

        for k = 1, childCount do
            local childProjectile = self:CreateChildProjectile(childBlueprint)

            -- sometimes the OnCreate is not called by the engine
            if not childProjectile.Trash then
                continue
            end

            -- inherit some properties
            childProjectile.Launcher = self.Launcher
            childProjectile.DamageData = self.DamageData
            childProjectile.CreatedByWeapon = self.CreatedByWeapon

            if inheritTargetGround then
                childProjectile:SetTurnRate(40)
                childProjectile:SetNewTargetGround(self:GetCurrentTargetPosition())
                childProjectile:TrackTarget(false)
            end

            childProjectile.Trash:Add(ForkThread(self.ZigZagThread, self, childProjectile))
        end
    end,

    --- Zig-zag the projectile to create some diversity
    ---@param self SplitComponent | Projectile
    ---@param childProjectile Projectile
    ZigZagThread = function(self, childProjectile)
        childProjectile:ChangeMaxZigZag(10)

        -- we need this or the zigzag does not work
        childProjectile:TrackTarget(true)

        WaitTicks(9)

        for k = 9, 1, -1 do
            if not IsDestroyed(childProjectile) then
                childProjectile:ChangeMaxZigZag(k)
                childProjectile:ChangeZigZagFrequency(0.1 * k)
            end

            WaitTicks(3)
        end

        if not IsDestroyed(childProjectile) then
            childProjectile:ChangeMaxZigZag(0.5)
            childProjectile:ChangeZigZagFrequency(1)
        end
    end,

}

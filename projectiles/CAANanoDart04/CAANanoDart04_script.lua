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

local CAANanoDartProjectile = import("/lua/cybranprojectiles.lua").CAANanoDartProjectile02
local CAANanoDartProjectileOnCreate = CAANanoDartProjectile.OnCreate

-- upvalue scope for performance
local ForkThread = ForkThread
local WaitTicks = WaitTicks

--- Cybran Anti Air Projectile
---@class CAANanoDart04: CAANanoDartProjectile02
CAANanoDart04 = ClassProjectile(CAANanoDartProjectile) {

    ---@param self CAANanoDart04
    OnCreate = function(self)
        CAANanoDartProjectileOnCreate(self)
        --Set the orientation of this thing to facing the target from the beginning.
        local px, py, pz = self:GetPositionXYZ()
        local targetPos = self:GetCurrentTargetPosition()

        --Determine and set the initial velocity of the projectile.
        self:SetVelocity(targetPos[1] - px, targetPos[2] - py - 40, targetPos[3] - pz)
        self.Trash:Add(ForkThread(self.UpdateThread, self))
    end,

    ---@param self CAANanoDart04
    UpdateThread = function(self)
        self:SetMaxSpeed(50) --Immediately go to max speed.
        WaitTicks(3) --Wait for a small amount of time
        self:SetBallisticAcceleration(-0.5) --Accelerate the projectile forward (negative is forward for this one).
        --Set the mesh for the unfolded-fins missile now.
        self:SetMesh('/projectiles/CAANanoDart01/CAANanoDartUnPacked01_mesh')
        self:SetAcceleration(8 + Random() * 5)
        --Wait a little bit more before letting this missile be able to turn through a full range of rotation
        -- in its tracking.
        WaitTicks(4)
        self:SetTurnRate(360)
    end,
}
TypeClass = CAANanoDart04

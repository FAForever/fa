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

local CAANanoDartProjectile = import("/lua/cybranprojectiles.lua").CAANanoDartProjectile
local CAANanoDartProjectileOnCreate = CAANanoDartProjectile.OnCreate

-- upvalue scope for performance
local WaitTicks = WaitTicks
local ForkThread = ForkThread
local TrashBagAdd = TrashBag.Add

--- Cybran Anti Air Projectile
---@class CAANanoDart01: CAANanoDartProjectile
CAANanoDart01 = ClassProjectile(CAANanoDartProjectile) {

    ---@param self CAANanoDart01
    OnCreate = function(self)
        CAANanoDartProjectileOnCreate(self)
        local trash = self.Trash
        TrashBagAdd(trash,ForkThread(self.UpdateThread, self))
    end,

    ---@param self CAANanoDart01
    UpdateThread = function(self)
        WaitTicks(3)
        self:SetMaxSpeed(10)
        self:SetBallisticAcceleration(-0.2)
        WaitTicks(3)
        self:SetMesh('/projectiles/CAANanoDart01/CAANanoDartUnPacked01_mesh')
        self:SetMaxSpeed(60)
        self:SetAcceleration(20 + Random() * 5)
        WaitTicks(4)
        self:SetTurnRate(360)
    end,
}
TypeClass = CAANanoDart01

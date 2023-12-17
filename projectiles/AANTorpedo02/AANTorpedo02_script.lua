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

local ATorpedoShipProjectile = import("/lua/aeonprojectiles.lua").ATorpedoShipProjectile
local ATorpedoShipProjectileOnCreate = ATorpedoShipProjectile.OnCreate

-- Upvalue for performance
local WaitTicks = WaitTicks
local ForkThread = ForkThread
local TrashBagAdd = TrashBag.Add

-- Aeon Torpedo Bomb
---@class AANTorpedo02 : ATorpedoShipProjectile
AANTorpedo02 = ClassProjectile(ATorpedoShipProjectile) {
    FxSplashScale = 1,
    FxTrailScale = 0.75,

    ---@param self AANTorpedo02
    ---@param inWater boolean
    OnCreate = function(self, inWater)
        ATorpedoShipProjectileOnCreate(self, inWater)
        local trash = self.Trash

        self:SetMaxSpeed(8)
        TrashBagAdd(trash,ForkThread(self.MotionThread, self))
    end,

    ---@param self AANTorpedo02
    MotionThread = function(self)
        WaitTicks(4)
        self:SetTurnRate(80)
        self:SetMaxSpeed(3)
        self:SetVelocity(3)
    end,
}
TypeClass = AANTorpedo02

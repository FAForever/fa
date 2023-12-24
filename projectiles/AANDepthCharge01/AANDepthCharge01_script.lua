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

local ADepthChargeProjectile = import("/lua/aeonprojectiles.lua").ADepthChargeProjectile
local VisionMarkerOpti = import("/lua/sim/vizmarker.lua").VisionMarkerOpti
local ADepthChargeProjectileOnCreate = ADepthChargeProjectile.OnCreate
local ADepthChargeProjectileOnEnterWater = ADepthChargeProjectile.OnEnterWater
local ADepthChargeProjectileOnImpact = ADepthChargeProjectile.OnImpact

-- upvalue for performance
local ForkThread = ForkThread
local TrashBagAdd = TrashBag.Add
local WaitTicks = WaitTicks





-- Depth Charge Script
---@class AANDepthCharge01 : ADepthChargeProjectile
---@field HasImpacted boolean
AANDepthCharge01 = ClassProjectile(ADepthChargeProjectile) {
    CountdownLengthInTicks = 101,

    ---@param self AANDepthCharge01
    OnCreate = function(self)
        ADepthChargeProjectileOnCreate(self)

        local trash = self.Trash

        self.HasImpacted = false
        TrashBagAdd(trash,ForkThread(self.CountdownExplosion, self))
    end,

    ---@param self AANDepthCharge01
    CountdownExplosion = function(self)
        WaitTicks(self.CountdownLengthInTicks)
        if not self.HasImpacted then
            self:OnImpact('Underwater', nil)
        end
    end,

    ---@param self AANDepthCharge01
    OnEnterWater = function(self)
        ADepthChargeProjectileOnEnterWater(self)
        self:SetMaxSpeed(20)
        self:SetVelocity(0)
        self:SetAcceleration(5)
        self:SetTurnRate(180)
    end,

    ---@param self AANDepthCharge01
    OnLostTarget = function(self)
        local trash = self.Trash

        self:SetMaxSpeed(2)
        self:SetAcceleration(-0.6)
        TrashBagAdd(trash,ForkThread(self.CountdownMovement, self))
    end,

    ---@param self AANDepthCharge01
    CountdownMovement = function(self)
        WaitTicks(31)
        self:SetMaxSpeed(0)
        self:SetAcceleration(0)
        self:SetVelocity(0)
    end,

    ---@param self AANDepthCharge01
    OnImpact = function(self, TargetType, TargetEntity)
        local army = self.Army
        local px, _, pz = self:GetPositionXYZ()
        local marker = VisionMarkerOpti({ Owner = self })

        marker:UpdatePosition(px, pz)
        marker:UpdateDuration(5)
        marker:UpdateIntel(army, 5, 'Vision', true)
        ADepthChargeProjectileOnImpact(self, TargetType, TargetEntity)
    end,
}
TypeClass = AANDepthCharge01

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
local ADepthChargeProjectileOnEnterWater = ADepthChargeProjectile.OnEnterWater
local ADepthChargeProjectileOnImpact = ADepthChargeProjectile.OnImpact

local VisionMarkerOpti = import("/lua/sim/vizmarker.lua").VisionMarkerOpti

-- Depth Charge Script
---@class AANDepthCharge03 : ADepthChargeProjectile
AANDepthCharge03 = ClassProjectile(ADepthChargeProjectile) {

    ---@param self AANDepthCharge03
    ---@param TargetType string
    ---@param TargetEntity Prop|Unit
    OnImpact = function(self, TargetType, TargetEntity)
        local px, _, pz = self:GetPositionXYZ()
        local marker = VisionMarkerOpti({ Owner = self })
        local army = self.Army

        marker:UpdatePosition(px, pz)
        marker:UpdateDuration(5)
        marker:UpdateIntel(army, 5, 'Vision', true)
        ADepthChargeProjectileOnImpact(self, TargetType, TargetEntity)
    end,

    ---@param self TANAnglerTorpedo06
    OnEnterWater = function(self)
        ADepthChargeProjectileOnEnterWater(self)

        -- set the magnitude of the velocity to something tiny to really make that water
        -- impact slow it down. We need this to prevent torpedo's striking the bottom
        -- of a shallow pond, like in setons
        self:SetVelocity(0)
        self:SetAcceleration(0.5)
    end,

    --- Adjusted movement thread to gradually speed up the torpedo. It needs to slowly speed
    --- up to prevent it from hitting the floor in relative undeep water
    ---@param self TANAnglerTorpedo06
    MovementThread = function(self)
        -- local scope for performance
        local WaitTicks = WaitTicks
        local IsDestroyed = IsDestroyed
        local ProjectileSetAcceleration = self.SetAcceleration

        for k = 1, 6 do
            WaitTicks(2)
            if not IsDestroyed(self) then
                ProjectileSetAcceleration(self, k)
            else
                break
            end
        end
    end,
}
TypeClass = AANDepthCharge03

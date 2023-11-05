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

local ATorpedoCluster = import("/lua/aeonprojectiles.lua").ATorpedoCluster
local ATorpedoClusterOnCreate = ATorpedoCluster.OnCreate
local ATorpedoClusterOnEnterWater = ATorpedoCluster.OnEnterWater

--- Aeon Torpedo Cluster Projectile script, XAA0306
---@class AANTorpedoCluster01 : ATorpedoCluster
AANTorpedoCluster01 = ClassProjectile(ATorpedoCluster) {
    FxTrail = import("/lua/effecttemplates.lua").ATorpedoPolyTrails01,

    ---@param self AANTorpedoCluster01
    ---@param inWater boolean
    OnCreate = function(self, inWater)
        ATorpedoClusterOnCreate(self, inWater)
        CreateTrail(self, -1, self.Army, import("/lua/effecttemplates.lua").ATorpedoPolyTrails01)
    end,

    ---@param self TANAnglerTorpedo06
    OnEnterWater = function(self)
        ATorpedoClusterOnEnterWater(self)

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
TypeClass = AANTorpedoCluster01

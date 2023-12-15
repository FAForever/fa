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

local VisionMarkerOpti = import("/lua/sim/vizmarker.lua").VisionMarkerOpti

-- upvalue scope for performance
local CreateTrail = CreateTrail

--- Aeon Torpedo Cluster Projectile script, XAA0306
---@class AANTorpedoCluster01 : ATorpedoCluster
AANTorpedoCluster01 = ClassProjectile(ATorpedoCluster) {
    FxTrail = import("/lua/effecttemplates.lua").ATorpedoPolyTrails01,

    ---@param self AANTorpedoCluster01
    OnCreate = function(self)
        local army = self.Army
        ATorpedoClusterOnCreate(self)
        CreateTrail(self, -1, army, self.FxTrail)
    end,

    ---@param self AANTorpedoCluster01
    OnEnterWater = function(self)
        local army = self.Army
        ATorpedoClusterOnEnterWater(self)

        -- create two child projectiles
        for i = 0, 1 do
            proj = self:CreateChildProjectile('/projectiles/AANTorpedoClusterSplit01/AANTorpedoClusterSplit01_proj.bp')
            proj.DamageData = self.DamageData
        end

        -- create vision
        local px, _, pz = self:GetPositionXYZ()
        local marker = VisionMarkerOpti({ Owner = self })
        marker:UpdatePosition(px, pz)
        marker:UpdateDuration(10)
        marker:UpdateIntel(army, 5, 'Vision', true)

        -- let the children live on
        self:Destroy()
    end,
}
TypeClass = AANTorpedoCluster01

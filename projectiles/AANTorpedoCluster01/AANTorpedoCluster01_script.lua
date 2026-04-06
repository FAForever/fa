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

local SplitComponent = import('/lua/sim/projectiles/components/splitcomponent.lua').SplitComponent

local VisionMarkerOpti = import("/lua/sim/vizmarker.lua").VisionMarkerOpti

-- upvalue scope for performance
local CreateTrail = CreateTrail

--- Aeon Torpedo Cluster Projectile script, XAA0306
---@class AANTorpedoCluster01 : ATorpedoCluster, SplitComponent
AANTorpedoCluster01 = ClassProjectile(ATorpedoCluster, SplitComponent) {
    FxTrail = import("/lua/effecttemplates.lua").ATorpedoPolyTrails01,

    ChildCount = 2,
    ChildProjectileBlueprint = "/projectiles/AANTorpedoClusterSplit01/AANTorpedoClusterSplit01_proj.bp",

    ---@param self AANTorpedoCluster01
    OnCreate = function(self)
        ATorpedoClusterOnCreate(self)
        CreateTrail(self, -1, self.Army, self.FxTrail)
    end,

    ---@param self AANTorpedoCluster01
    OnEnterWater = function(self)
        ATorpedoClusterOnEnterWater(self)

        -- split damage over each child
        self.DamageData.DamageAmount = self.DamageData.DamageAmount / self.ChildCount

        -- create child projectiles
        self:OnSplit(false)

        -- create vision
        local px, _, pz = self:GetPositionXYZ()
        local marker = VisionMarkerOpti({ Owner = self })
        marker:UpdatePosition(px, pz)
        marker:UpdateDuration(10)
        marker:UpdateIntel(self.Army, 5, 'Vision', true)

        self:Destroy()
    end,
}
TypeClass = AANTorpedoCluster01

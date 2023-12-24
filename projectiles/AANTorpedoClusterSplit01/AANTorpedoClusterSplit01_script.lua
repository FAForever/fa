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
local ATorpedoPolyTrails01 = import("/lua/effecttemplates.lua").ATorpedoPolyTrails01
local VisionMarkerOpti = import("/lua/sim/vizmarker.lua").VisionMarkerOpti
local ATorpedoClusterOnCreate = ATorpedoCluster.OnCreate
local ATorpedoClusterOnImpact = ATorpedoCluster.OnImpact

-- upvalue for performance
local ForkThread = ForkThread
local WaitTicks = WaitTicks
local TrashBagAdd = TrashBag.Add

--- Aeon Torpedo Cluster Projectile script, XAA0306
---@class AANTorpedoClusterSplit01 : ATorpedoCluster
AANTorpedoClusterSplit01 = ClassProjectile(ATorpedoCluster) {
    CountdownLength = 101,

    ---@param self AANTorpedoClusterSplit01
    OnCreate = function(self)
        ATorpedoClusterOnCreate(self)
        local trash = self.Trash
        local army = self.Army

        TrashBagAdd(trash,ForkThread(self.CountdownExplosion, self))
        CreateTrail(self, -1, army, ATorpedoPolyTrails01)
    end,

    ---@param self AANTorpedoClusterSplit01
    CountdownExplosion = function(self)
        WaitTicks(self.CountdownLength)
        self:OnImpact('Underwater', nil)
    end,

    --- Adjusted movement thread to gradually speed up the torpedo. It needs to slowly speed
    --- up to prevent it from hitting the floor in relative undeep water
    ---@param self TANAnglerTorpedo06
    MovementThread = function(self)
        -- local scope for performance
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

    ---@param self AANTorpedoClusterSplit01
    OnLostTarget = function(self)
        local trash = self.Trash

        self:SetMaxSpeed(2)
        self:SetAcceleration(-0.6)
        TrashBagAdd(trash,ForkThread(self.CountdownMovement, self))
    end,

    ---@param self AANTorpedoClusterSplit01
    CountdownMovement = function(self)
        WaitTicks(31)
        self:SetMaxSpeed(0)
        self:SetAcceleration(0)
        self:SetVelocity(0)
    end,

    ---@param self AANTorpedoClusterSplit01
    ---@param TargetType string
    ---@param TargetEntity Prop|Unit
    OnImpact = function(self, TargetType, TargetEntity)
        local px, _, pz = self:GetPositionXYZ()
        local marker = VisionMarkerOpti({ Owner = self })
        local army = self.Army
        marker:UpdatePosition(px, pz)
        marker:UpdateDuration(5)
        marker:UpdateIntel(army, 5, 'Vision', true)
        ATorpedoClusterOnImpact(self, TargetType, TargetEntity)
    end,
}
TypeClass = AANTorpedoClusterSplit01

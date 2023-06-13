------------------------------------------------------------------------------------------------
-- File     :  /data/projectiles/AANTorpedoClusterSplit01/AANTorpedoClusterSplit01_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Aeon Torpedo Cluster Projectile script, XAA0306
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------------------------------------
local ATorpedoCluster = import("/lua/aeonprojectiles.lua").ATorpedoCluster
local VisionMarkerOpti = import("/lua/sim/vizmarker.lua").VisionMarkerOpti

AANTorpedoCluster01 = ClassProjectile(ATorpedoCluster) {
    CountdownLength = 101,

    OnCreate = function(self)
        ATorpedoCluster.OnCreate(self)
        self.HasImpacted = false
        self.Trash:Add(ForkThread(self.CountdownExplosion,self))
		CreateTrail(self, -1, self.Army, import("/lua/effecttemplates.lua").ATorpedoPolyTrails01)

    end,

    CountdownExplosion = function(self)
        WaitTicks(self.CountdownLength)
        if not self.HasImpacted then
            self:OnImpact('Underwater', nil)
        end
    end,

    --- Adjusted movement thread to gradually speed up the torpedo. It needs to slowly speed
    --- up to prevent it from hitting the floor in relative undeep water
    ---@param self TANAnglerTorpedo06
    MovementThread = function(self)
        WaitTicks(1)
        for k = 1, 6 do
            WaitTicks(1)
            if not IsDestroyed(self) then
                self:SetAcceleration(k)
            else
                break
            end
        end
    end,

    OnLostTarget = function(self)
        self:SetMaxSpeed(2)
        self:SetAcceleration(-0.6)
        self.Trash:Add(ForkThread(self.CountdownMovement,self))
    end,

    CountdownMovement = function(self)
        WaitTicks(31)
        self:SetMaxSpeed(0)
        self:SetAcceleration(0)
        self:SetVelocity(0)
    end,

    OnImpact = function(self, TargetType, TargetEntity)
        local px,_,pz = self:GetPositionXYZ()
        local marker = VisionMarkerOpti({Owner = self})
        marker:UpdatePosition(px,pz)
        marker:UpdateDuration(5)
        marker:UpdateIntel(self.Army, 5,'Vision',true)
        ATorpedoCluster.OnImpact(self, TargetType, TargetEntity)
    end,
}
TypeClass = AANTorpedoCluster01
------------------------------------------------------------------------------------------------
-- File     :  /data/projectiles/AANTorpedoClusterSplit01/AANTorpedoClusterSplit01_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Aeon Torpedo Cluster Projectile script, XAA0306
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------------------------------------
local ATorpedoCluster = import("/lua/aeonprojectiles.lua").ATorpedoCluster
local VisionMarkerOpti = import("/lua/sim/vizmarker.lua").VisionMarkerOpti

AANTorpedoCluster01 = ClassProjectile(ATorpedoCluster) {

    FxTrail = import("/lua/effecttemplates.lua").ATorpedoPolyTrails01,

    OnCreate = function(self, inWater)
        ATorpedoCluster.OnCreate(self, inWater)
        CreateTrail(self, -1, self.Army, import("/lua/effecttemplates.lua").ATorpedoPolyTrails01)
    end,

    ---@param self TANAnglerTorpedo06
    OnEnterWater = function(self)
        ATorpedoCluster.OnEnterWater(self)

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
}
TypeClass = AANTorpedoCluster01
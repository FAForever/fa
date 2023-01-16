---------------------------------------------------------------------------------------
-- File     :  /data/projectiles/AANTorpedoCluster01/AANTorpedoCluster01_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Aeon Torpedo Cluster Projectile script, XAA0306
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------------------------
local ATorpedoCluster = import("/lua/aeonprojectiles.lua").ATorpedoCluster
local VisionMarkerOpti = import("/lua/sim/vizmarker.lua").VisionMarkerOpti

-- upvalue scope for performance
local CreateTrail = CreateTrail

AANTorpedoCluster01 = ClassProjectile(ATorpedoCluster) {
    FxTrail = import("/lua/effecttemplates.lua").ATorpedoPolyTrails01,

    OnCreate = function(self)
        ATorpedoCluster.OnCreate(self)
		CreateTrail(self, -1, self.Army, self.FxTrail)
    end,

    OnEnterWater = function(self) 
        ATorpedoCluster.OnEnterWater(self)

        -- create two child projectiles
        for i = 0, 1 do
            proj = self:CreateChildProjectile('/projectiles/AANTorpedoClusterSplit01/AANTorpedoClusterSplit01_proj.bp' )
            proj.DamageData = self.DamageData
        end
        local px, _,pz = self:GetPositionXYZ()
        local marker = VisionMarkerOpti({Owner = self})
        marker:UpdatePosition(px,pz)
        marker:UpdateDuration(10)
        marker:UpdateIntel(self.Army,5,'Vision',true)
        self:Destroy()
    end,
}
TypeClass = AANTorpedoCluster01
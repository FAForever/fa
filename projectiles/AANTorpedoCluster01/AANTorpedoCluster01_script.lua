--****************************************************************************
--**
--**  File     :  /data/projectiles/AANTorpedoCluster01/AANTorpedoCluster01_script.lua
--**  Author(s):  Gordon Duclos
--**
--**  Summary  :  Aeon Torpedo Cluster Projectile script, XAA0306
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local ATorpedoCluster = import("/lua/aeonprojectiles.lua").ATorpedoCluster
local VizMarker = import("/lua/sim/vizmarker.lua").VizMarker

-- cache specification table 
local CachedSpecifications = {
    X = 0,
    Z = 0,
    Radius = 30,
    LifeTime = 10,
    Omni = false,
    Vision = false,
    Army = 0,
}

-- upvalue scope for performance
local CreateTrail = CreateTrail

AANTorpedoCluster01 = Class(ATorpedoCluster) {

    FxTrail = import("/lua/effecttemplates.lua").ATorpedoPolyTrails01,

    FxEnterWater= { 
        '/effects/emitters/water_splash_ripples_ring_01_emit.bp',
        '/effects/emitters/water_splash_plume_01_emit.bp',
    },

    OnCreate = function(self)
        ATorpedoCluster.OnCreate(self)
		CreateTrail(self, -1, self.Army, self.FxTrail)
    end,

    OnEnterWater = function(self) 
        ATorpedoCluster.OnEnterWater(self)
        
        -- create two child projectiles
        for i = 0, 1 do
            proj = self:CreateChildProjectile('/projectiles/AANTorpedoClusterSplit01/AANTorpedoClusterSplit01_proj.bp' )
            proj:PassDamageData(self.DamageData)
        end            
        
        local pos = self:GetPosition()
        local spec = CachedSpecifications
        spec.X = pos[1] 
        spec.Z = pos[3]
        spec.Army = self.Army 

        local vizEntity = VizMarker(spec)

        self:Destroy()
    end,
}
TypeClass = AANTorpedoCluster01

-- kept for mod backwards compatibility
local RandomFloat = import("/lua/utilities.lua").GetRandomFloat
#****************************************************************************
#**
#**  File     :  /data/projectiles/AANTorpedoClusterSplit01/AANTorpedoClusterSplit01_script.lua
#**  Author(s):  Gordon Duclos
#**
#**  Summary  :  Aeon Torpedo Cluster Projectile script, XAA0306
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local ATorpedoCluster = import('/lua/aeonprojectiles.lua').ATorpedoCluster
local VizMarker = import('/lua/sim/VizMarker.lua').VizMarker

AANTorpedoCluster01 = Class(ATorpedoCluster) {

    CountdownLength = 10,
    FxEnterWater= { '/effects/emitters/water_splash_ripples_ring_01_emit.bp',
                    '/effects/emitters/water_splash_plume_01_emit.bp',},

    OnCreate = function(self)
        ATorpedoCluster.OnCreate(self)
        self.HasImpacted = false
        self:ForkThread(self.CountdownExplosion)

		CreateTrail(self, -1, self:GetArmy(), import('/lua/EffectTemplates.lua').ATorpedoPolyTrails01)
        
    end,

    CountdownExplosion = function(self)
        WaitSeconds(self.CountdownLength)

        if not self.HasImpacted then
            self.OnImpact(self, 'Underwater', nil)
        end
    end,

    OnEnterWater = function(self)
        ATorpedoCluster.OnEnterWater(self)
        local army = self:GetArmy()
        for i in self.FxEnterWater do #splash
            CreateEmitterAtEntity(self,army,self.FxEnterWater[i])
        end
        self:ForkThread(self.EnterWaterMovementThread)
    end,
    
    EnterWaterMovementThread = function(self)
        #self:SetMaxSpeed(20)
        #self:SetVelocity(1)
        #WaitSeconds(0.1)
        self:SetAcceleration(2.5)
		    #self:SetVelocity(2)
        self:TrackTarget(true)
        self:StayUnderwater(true)
        self:SetTurnRate(180)
        self:SetStayUpright(false)
    end,

    OnLostTarget = function(self)
        self:SetMaxSpeed(2)
        self:SetAcceleration(-0.6)
        self:ForkThread(self.CountdownMovement)
    end,

    CountdownMovement = function(self)
        WaitSeconds(3)
        self:SetMaxSpeed(0)
        self:SetAcceleration(0)
        self:SetVelocity(0)
    end,

    OnImpact = function(self, TargetType, TargetEntity)
        self.HasImpacted = true
        local pos = self:GetPosition()
        local spec = {
            X = pos[1],
            Z = pos[3],
            Radius = 30,
            LifeTime = 10,
            Omni = false,
            Vision = false,
            Army = self:GetArmy(),
        }
        local vizEntity = VizMarker(spec)
        ATorpedoCluster.OnImpact(self, TargetType, TargetEntity)
    end,
}
TypeClass = AANTorpedoCluster01
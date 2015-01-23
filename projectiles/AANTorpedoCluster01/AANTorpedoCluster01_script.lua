#****************************************************************************
#**
#**  File     :  /data/projectiles/AANTorpedoCluster01/AANTorpedoCluster01_script.lua
#**  Author(s):  Gordon Duclos
#**
#**  Summary  :  Aeon Torpedo Cluster Projectile script, XAA0306
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local ATorpedoCluster = import('/lua/aeonprojectiles.lua').ATorpedoCluster
local VizMarker = import('/lua/sim/VizMarker.lua').VizMarker
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

AANTorpedoCluster01 = Class(ATorpedoCluster) {

    FxEnterWater= { '/effects/emitters/water_splash_ripples_ring_01_emit.bp',
                    '/effects/emitters/water_splash_plume_01_emit.bp',},

    OnCreate = function(self)
        ATorpedoCluster.OnCreate(self)
        self.HasImpacted = false

		CreateTrail(self, -1, self:GetArmy(), import('/lua/EffectTemplates.lua').ATorpedoPolyTrails01)
        
    end,

    OnEnterWater = function(self) 

        local Velx, Vely, Velz = self:GetVelocity()
        local NumberOfChildProjectiles = 1        
        local ChildProjectileBP = '/projectiles/AANTorpedoClusterSplit01/AANTorpedoClusterSplit01_proj.bp'  
        local angleRange = math.pi * 0.25
        local angleInitial = -angleRange / 2
        local angleIncrement = angleRange / NumberOfChildProjectiles
        local angleVariation = angleIncrement * 0.4
        local angle, ca, sa, x, z, proj, mul
        
        self:StayUnderwater(true)
        for i = 0, NumberOfChildProjectiles  do
            angle = angleInitial + (i*angleIncrement) + RandomFloat(-angleVariation, angleVariation)
            ca = math.cos(angle)
            sa = math.sin(angle)
            x = Velx * ca - Velz * sa
            z = Velx * sa + Velz * ca
            proj = self:CreateChildProjectile(ChildProjectileBP)
            proj:PassDamageData(self.DamageData)
            mul = RandomFloat(1,3)
            #proj:SetVelocity( x * mul, Vely * mul, z * mul )
        end            
        
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
        ATorpedoCluster.OnEnterWater(self)
        self:Destroy()
    end,
    
    OnImpact = function(self, TargetType, TargetEntity)
        if (TargetEntity == nil) and (TargetType == "Air") then
            return
        end
        ATorpedoCluster.OnImpact(self, TargetType, TargetEntity)
    end,
}
TypeClass = AANTorpedoCluster01
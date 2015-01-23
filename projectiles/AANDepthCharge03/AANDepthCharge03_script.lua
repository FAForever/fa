-- Depth Charge Script
local ADepthChargeProjectile = import('/lua/aeonprojectiles.lua').ADepthChargeProjectile
local VizMarker = import('/lua/sim/VizMarker.lua').VizMarker

AANDepthCharge03 = Class(ADepthChargeProjectile) {

    FxEnterWater = { '/effects/emitters/water_splash_ripples_ring_01_emit.bp',
                    '/effects/emitters/water_splash_plume_01_emit.bp',},

    OnCreate = function(self)
        ADepthChargeProjectile.OnCreate(self)
        self.HasImpacted = false
        self:ForkThread(self.CountdownExplosion, 10)
    end,

    CountdownExplosion = function(self, countdown)
        WaitSeconds(countdown)

        if not self.HasImpacted then
            self.OnImpact(self, 'Underwater', nil)
        end
    end,
    
    OnEnterWater = function(self)
        local army = self:GetArmy()
        
        for i in self.FxEnterWater do
            CreateEmitterAtEntity(self,army,self.FxEnterWater[i])
        end
        
        self:SetVelocity(4)
        self:TrackTarget(true)
        self:StayUnderwater(true)
        self:SetTurnRate(360)
        self:SetVelocityAlign(true)
        self:SetStayUpright(false)
        self:ForkThread(self.EnterWaterMovementThread)
    end,
    
    EnterWaterMovementThread = function(self)
        WaitTicks(1)
        self:SetAcceleration(5)
    end,

    OnLostTarget = function(self)
        self:SetMaxSpeed(4)
        self:SetAcceleration(-5)
        self:ForkThread(self.CountdownMovement)
    end,

    CountdownMovement = function(self)
        WaitSeconds(2)
        self:SetMaxSpeed(0)
        self:SetAcceleration(-4)
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
        ADepthChargeProjectile.OnImpact(self, TargetType, TargetEntity)
    end,
}

TypeClass = AANDepthCharge03
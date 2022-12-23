-- Depth Charge Script

local ADepthChargeProjectile = import("/lua/aeonprojectiles.lua").ADepthChargeProjectile
local VizMarker = import("/lua/sim/vizmarker.lua").VizMarker

AANDepthCharge03 = Class(ADepthChargeProjectile) {

    CountdownLength = 10,
    FxEnterWater= { '/effects/emitters/water_splash_ripples_ring_01_emit.bp',
                    '/effects/emitters/water_splash_plume_01_emit.bp',},

    OnCreate = function(self)
        ADepthChargeProjectile.OnCreate(self)
        self.HasImpacted = false
        self:ForkThread(self.CountdownExplosion)
    end,

    CountdownExplosion = function(self)
        WaitSeconds(self.CountdownLength)

        if not self.HasImpacted then
            self:OnImpact('Underwater', nil)
        end
    end,

    OnEnterWater = function(self)
        for i in self.FxEnterWater do --splash
            CreateEmitterAtEntity(self, self.Army, self.FxEnterWater[i])
        end

        self:TrackTarget(true)
        self:StayUnderwater(true)
        self:SetTurnRate(360)
        self:SetVelocityAlign(true)
        self:SetStayUpright(false)
    end,

    EnterWaterMovementThread = function(self)
        WaitTicks(1)
        self:SetVelocity(0.5)
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
            Army = self.Army,
        }
        local vizEntity = VizMarker(spec)
        ADepthChargeProjectile.OnImpact(self, TargetType, TargetEntity)
    end,
}
TypeClass = AANDepthCharge03
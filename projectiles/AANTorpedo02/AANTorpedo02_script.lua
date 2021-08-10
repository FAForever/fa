--
-- Aeon Torpedo Bomb
--
local ATorpedoShipProjectile= import('/lua/aeonprojectiles.lua').ATorpedoShipProjectile

AANTorpedo02 = Class(ATorpedoShipProjectile) {
    FxSplashScale = 1,
    FxTrailScale = 0.75,
    FxEnterWater= { '/effects/emitters/water_splash_ripples_ring_01_emit.bp',
                    '/effects/emitters/water_splash_plume_01_emit.bp',},

    OnEnterWater = function(self)
        ATorpedoShipProjectile.OnEnterWater(self)
        local army = self:GetArmy()
        for k, v in self.FxEnterWater do --splash
            CreateEmitterAtEntity(self, army, v):ScaleEmitter(self.FxSplashScale)
        end
    end,

    OnCreate = function(self, inWater)
        ATorpedoShipProjectile.OnCreate(self, inWater)
        self:SetMaxSpeed(8)
        self:ForkThread( self.MotionThread ) 
    end,

    MotionThread = function(self)
        WaitSeconds( 0.3 )
        self:SetTurnRate(80)
        self:SetMaxSpeed(3)
        self:SetVelocity(3)
    end,
}

TypeClass = AANTorpedo02

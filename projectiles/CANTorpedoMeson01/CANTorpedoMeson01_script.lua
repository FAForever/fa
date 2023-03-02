--
-- Cybran Non-guided Torpedo, Made to be fired from above the water
--
local CTorpedoShipProjectile = import("/lua/cybranprojectiles.lua").CTorpedoShipProjectile

CANTorpedoMeson01 = Class(CTorpedoShipProjectile) {
    FxSplashScale = 1,

    FxExitWaterEmitter = {
        '/effects/emitters/destruction_water_splash_ripples_01_emit.bp',
        '/effects/emitters/destruction_water_splash_wash_01_emit.bp',
        '/effects/emitters/destruction_water_splash_plume_01_emit.bp',
    },

    OnEnterWater = function(self)
        CTorpedoShipProjectile.OnEnterWater(self)
        local army = self:GetArmy()

        for i in self.FxExitWaterEmitter do --splash
            CreateEmitterAtEntity(self,army,self.FxExitWaterEmitter[i]):ScaleEmitter(self.FxSplashScale)
        end

        self:TrackTarget(true)
        self:StayUnderwater(true)
        self:SetBallisticAcceleration(0)
        self:SetTurnRate(120)
        self:SetMaxSpeed(18)
        self:SetVelocity(3)
        self:ForkThread(self.SpinUpThread)
    end,

	SpinUpThread = function(self)
        WaitSeconds(2)
        self:TrackTarget(false)
        self:SetTurnRate(0)
	end,
}

TypeClass = CANTorpedoMeson01

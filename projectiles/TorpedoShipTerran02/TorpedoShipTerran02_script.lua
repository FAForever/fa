--
-- Terran Land-based torpedo
--
local TTorpedoShipProjectile = import('/lua/terranprojectiles.lua').TTorpedoShipProjectile
TorpedoShipTerran02 = Class(TTorpedoShipProjectile) {
    FxSplashScale = 1,

    -- copied from terran projectiles, TMissileCruiseSubProjectile
    FxExitWaterEmitter = {
        '/effects/emitters/destruction_water_splash_ripples_01_emit.bp',
        '/effects/emitters/destruction_water_splash_wash_01_emit.bp',
        '/effects/emitters/destruction_water_splash_plume_01_emit.bp',
    },

    --OnCreate = function(self)
    --    TMissileCruiseSubProjectile.OnCreate(self)
    --    self:SetScale(0.6)
    --end

    OnEnterWater = function(self)
        TTorpedoShipProjectile.OnEnterWater(self)

        for i in self.FxExitWaterEmitter do --splash
            CreateEmitterAtEntity(self,self.Army,self.FxExitWaterEmitter[i]):ScaleEmitter(self.FxSplashScale)
        end

        self:TrackTarget(true)
        self:StayUnderwater(true)
        self:SetTurnRate(60)
        self:SetMaxSpeed(3)
        self:SetVelocity(3)
    end,
}

TypeClass = TorpedoShipTerran02


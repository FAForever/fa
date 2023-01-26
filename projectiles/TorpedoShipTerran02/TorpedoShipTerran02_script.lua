-- Terran Land-based torpedo

local TTorpedoShipProjectile = import("/lua/terranprojectiles.lua").TTorpedoShipProjectile

--- Unused
---@class TorpedoShipTerran02 : TTorpedoShipProjectile
TorpedoShipTerran02 = Class(TTorpedoShipProjectile) {
    FxSplashScale = 1,

    -- copied from terran projectiles, TMissileCruiseSubProjectile
    FxExitWaterEmitter = {
        '/effects/emitters/destruction_water_splash_ripples_01_emit.bp',
        '/effects/emitters/destruction_water_splash_wash_01_emit.bp',
        '/effects/emitters/destruction_water_splash_plume_01_emit.bp',
    },

    ---@param self TorpedoShipTerran02
    OnEnterWater = function(self)
        TTorpedoShipProjectile.OnEnterWater(self)

        for i in self.FxExitWaterEmitter do --splash
            if self.FxSplashScale ~= 1 then
                CreateEmitterAtEntity(self, self:GetArmy(), self.FxExitWaterEmitter[i])
            else
                CreateEmitterAtEntity(self, self:GetArmy(), self.FxExitWaterEmitter[i]):ScaleEmitter(self.FxSplashScale)
            end
        end

        self:TrackTarget(true)
        self:StayUnderwater(true)
        self:SetTurnRate(60)
        self:SetMaxSpeed(3)
        self:SetVelocity(3)
    end,
}

TypeClass = TorpedoShipTerran02

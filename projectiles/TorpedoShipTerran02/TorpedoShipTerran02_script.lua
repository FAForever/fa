-- Terran Land-based torpedo

local TTorpedoShipProjectile = import("/lua/terranprojectiles.lua").TTorpedoShipProjectile

--- Unused
---@class TorpedoShipTerran02 : TTorpedoShipProjectile
TorpedoShipTerran02 = ClassProjectile(TTorpedoShipProjectile) {
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

        self:TrackTarget(true)
        self:StayUnderwater(true)
        self:SetTurnRate(60)
        self:SetMaxSpeed(3)
        self:SetVelocity(3)
    end,
}

TypeClass = TorpedoShipTerran02

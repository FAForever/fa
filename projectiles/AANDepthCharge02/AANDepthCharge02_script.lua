#
# Depth Charge Script
#
local ADepthChargeProjectile = import('/lua/aeonprojectiles.lua').ADepthChargeProjectile
local VizMarker = import('/lua/sim/VizMarker.lua').VizMarker

AANDepthCharge01 = Class(ADepthChargeProjectile) {

    FxEnterWater= { '/effects/emitters/water_splash_ripples_ring_01_emit.bp',
                    '/effects/emitters/water_splash_plume_01_emit.bp',},

    OnImpact = function(self, TargetType, TargetEntity)
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

TypeClass = AANDepthCharge01
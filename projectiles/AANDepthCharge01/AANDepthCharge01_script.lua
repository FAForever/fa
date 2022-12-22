-- Depth Charge Script

local ADepthChargeProjectile = import("/lua/aeonprojectiles.lua").ADepthChargeProjectile
local VisionMarkerOpti = import("/lua/sim/VizMarker.lua").VisionMarkerOpti

AANDepthCharge01 = Class(ADepthChargeProjectile) {

    CountdownLengthInTicks = 100,
    FxEnterWater= {
        '/effects/emitters/water_splash_ripples_ring_01_emit.bp',
        '/effects/emitters/water_splash_plume_01_emit.bp',
    },

    OnCreate = function(self)
        ADepthChargeProjectile.OnCreate(self)
        self.HasImpacted = false
        self.Trash:Add(ForkThread(self.CountdownExplosion, self))
    end,

    CountdownExplosion = function(self)
        WaitTicks(self.CountdownLengthInTicks)
        if not self.HasImpacted then
            self:OnImpact('Underwater', nil)
        end
    end,

    OnLostTarget = function(self)
        self:SetMaxSpeed(2)
        self:SetAcceleration(-0.6)
        self.Trash:Add(ForkThread(self.CountdownMovement, self))
    end,

    CountdownMovement = function(self)
        WaitTicks(30)
        self:SetMaxSpeed(0)
        self:SetAcceleration(0)
        self:SetVelocity(0)
    end,

    OnImpact = function(self, TargetType, TargetEntity)
        local px, _, pz = self:GetPositionXYZ()
        local marker = VisionMarkerOpti({Owner = self})
        marker:UpdatePosition(px, pz)
        marker:UpdateDuration(5)
        marker:UpdateIntel(self.Army, 5, 'Vision', true)
        ADepthChargeProjectile.OnImpact(self, TargetType, TargetEntity)
    end,
}
TypeClass = AANDepthCharge01
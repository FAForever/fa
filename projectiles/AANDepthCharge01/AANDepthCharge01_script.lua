-- Depth Charge Script
local ADepthChargeProjectile = import("/lua/aeonprojectiles.lua").ADepthChargeProjectile
local VisionMarkerOpti = import("/lua/sim/VizMarker.lua").VisionMarkerOpti

AANDepthCharge01 = ClassProjectile(ADepthChargeProjectile) {
    CountdownLengthInTicks = 101,

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

    OnEnterWater = function(self)
        ADepthChargeProjectile.OnEnterWater(self)
        self:SetMaxSpeed(20)
        self:SetVelocity(0)
        self:SetAcceleration(5)
        self:SetTurnRate(180)
    end,

    OnLostTarget = function(self)
        self:SetMaxSpeed(2)
        self:SetAcceleration(-0.6)
        self.Trash:Add(ForkThread(self.CountdownMovement, self))
    end,

    CountdownMovement = function(self)
        WaitTicks(31)
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
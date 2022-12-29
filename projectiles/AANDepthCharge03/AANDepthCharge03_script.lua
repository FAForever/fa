-- Depth Charge Script
local ADepthChargeProjectile = import("/lua/aeonprojectiles.lua").ADepthChargeProjectile
local VisionMarkerOpti = import("/lua/sim/vizmarker.lua").VisionMarkerOpti

AANDepthCharge03 = Class(ADepthChargeProjectile) {
    CountdownLength = 101,

    OnCreate = function(self)
        ADepthChargeProjectile.OnCreate(self)
        self.HasImpacted = false
        self.Trash:Add(ForkThread(self.CountdownExplosion,self))
    end,

    CountdownExplosion = function(self)
        WaitTicks(self.CountdownLength)
        if not self.HasImpacted then
            self:OnImpact('Underwater', nil)
        end
    end,

    OnEnterWater = function(self)
        ADepthChargeProjectile.OnEnterWater(self)
        self:SetTurnRate(360)
    end,

    OnLostTarget = function(self)
        self:SetMaxSpeed(2)
        self:SetAcceleration(-0.6)
        self.Trash:Add(ForkThread(self.CountdownMovement,self))
    end,

    CountdownMovement = function(self)
        WaitTicks(31)
        self:SetMaxSpeed(0)
        self:SetAcceleration(0)
        self:SetVelocity(0)
    end,

    OnImpact = function(self, TargetType, TargetEntity)
        local px,_,pz = self:GetPositionXYZ()
        local marker = VisionMarkerOpti({Owner = self})
        marker:UpdatePostion(px,pz)
        marker:UpdateDuration(5)
        marker:UpdateIntel(self.Army, 5, 'Vision', true)
        ADepthChargeProjectile.OnImpact(self, TargetType, TargetEntity)
    end,
}
TypeClass = AANDepthCharge03
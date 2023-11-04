local ADepthChargeProjectile = import("/lua/aeonprojectiles.lua").ADepthChargeProjectile
local VisionMarkerOpti = import("/lua/sim/vizmarker.lua").VisionMarkerOpti

-- Depth Charge Script
---@class AANDepthCharge01 : ADepthChargeProjectile
AANDepthCharge01 = ClassProjectile(ADepthChargeProjectile) {
    CountdownLengthInTicks = 101,

    ---@param self AANDepthCharge01
    OnCreate = function(self)
        ADepthChargeProjectile.OnCreate(self)
        self.HasImpacted = false
        self.Trash:Add(ForkThread(self.CountdownExplosion, self))
    end,

    ---@param self AANDepthCharge01
    CountdownExplosion = function(self)
        WaitTicks(self.CountdownLengthInTicks)
        if not self.HasImpacted then
            self:OnImpact('Underwater', nil)
        end
    end,

    ---@param self AANDepthCharge01
    OnEnterWater = function(self)
        ADepthChargeProjectile.OnEnterWater(self)
        self:SetMaxSpeed(20)
        self:SetVelocity(0)
        self:SetAcceleration(5)
        self:SetTurnRate(180)
    end,

    ---@param self AANDepthCharge01
    OnLostTarget = function(self)
        self:SetMaxSpeed(2)
        self:SetAcceleration(-0.6)
        self.Trash:Add(ForkThread(self.CountdownMovement, self))
    end,

    ---@param self AANDepthCharge01
    CountdownMovement = function(self)
        WaitTicks(31)
        self:SetMaxSpeed(0)
        self:SetAcceleration(0)
        self:SetVelocity(0)
    end,

    ---@param self AANDepthCharge01
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
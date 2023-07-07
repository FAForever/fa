-- Depth Charge Script
local ADepthChargeProjectile = import("/lua/aeonprojectiles.lua").ADepthChargeProjectile
local VisionMarkerOpti = import("/lua/sim/vizmarker.lua").VisionMarkerOpti

---@class AANDepthCharge03: ADepthChargeProjectile
AANDepthCharge03 = ClassProjectile(ADepthChargeProjectile) {
    CountdownLength = 101,

    ---@param self AANDepthCharge03
    OnCreate = function(self)
        ADepthChargeProjectile.OnCreate(self)
        self.HasImpacted = false
        self.Trash:Add(ForkThread(self.CountdownExplosion,self))
    end,

    ---@param self AANDepthCharge03
    CountdownExplosion = function(self)
        WaitTicks(self.CountdownLength)
        if not self.HasImpacted then
            self:OnImpact('Underwater', nil)
        end
    end,

    ---@param self AANDepthCharge03
    OnEnterWater = function(self)
        ADepthChargeProjectile.OnEnterWater(self)
        self:SetTurnRate(360)
    end,

    ---@param self AANDepthCharge03
    OnLostTarget = function(self)
        self:SetMaxSpeed(2)
        self:SetAcceleration(-0.6)
        self.Trash:Add(ForkThread(self.CountdownMovement,self))
    end,

    ---@param self AANDepthCharge03
    CountdownMovement = function(self)
        WaitTicks(31)
        self:SetMaxSpeed(0)
        self:SetAcceleration(0)
        self:SetVelocity(0)
    end,

    ---@param self AANDepthCharge03
    ---@param TargetType string
    ---@param TargetEntity Unit
    OnImpact = function(self, TargetType, TargetEntity)
        local px,_,pz = self:GetPositionXYZ()
        local marker = VisionMarkerOpti({Owner = self})
        marker:UpdatePosition(px,pz)
        marker:UpdateDuration(5)
        marker:UpdateIntel(self.Army, 5, 'Vision', true)
        ADepthChargeProjectile.OnImpact(self, TargetType, TargetEntity)
    end,
}
TypeClass = AANDepthCharge03
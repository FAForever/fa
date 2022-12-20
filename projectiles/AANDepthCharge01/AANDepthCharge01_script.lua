-- Depth Charge Script

local ADepthChargeProjectile = import("/lua/aeonprojectiles.lua").ADepthChargeProjectile
local VisionMarkerOpti = import("/lua/sim/vizmarker.lua").VisionMarkerOpti

AANDepthCharge01 = Class(ADepthChargeProjectile) {
    
    OnCreate = function(self)
        ADepthChargeProjectile.OnCreate(self)
        self.HasImpacted = false
        self:ForkThread(self.CountdownExplosion)
    end,

    CountdownExplosion = function(self)
        WaitSeconds(self.CountdownLength)

        if not self.HasImpacted then
            self:OnImpact('Underwater', nil)
        end
    end,

    OnEnterWater = function(self)
        self:SetMaxSpeed(20)
        self:SetVelocity(0)
        self:SetAcceleration(5)
        self:SetTurnRate(180)
    end,
    
    OnLostTarget = function(self)
        self:SetMaxSpeed(2)
        self:SetAcceleration(-0.6)
        self:ForkThread(self.CountdownMovement)
    end,

    CountdownMovement = function(self)
        WaitSeconds(3)
        self:SetMaxSpeed(0)
        self:SetAcceleration(0)
        self:SetVelocity(0)
    end,

    OnImpact = function(self, TargetType, TargetEntity)
        --LOG('Projectile impacted with: ' .. TargetType)
        self.HasImpacted = true
        local px,_,pz = self:GetPositionXYZ()
        local marker = VisionMarkerOpti({Owner = self})
        marker:UpdatePostion(px,pz)
        marker:UpdateDuration(5)
        marker:UpdateIntel(self.Army, 5, 'Vision', true)
        ADepthChargeProjectile.OnImpact(self, TargetType, TargetEntity)
    end,
}

TypeClass = AANDepthCharge01
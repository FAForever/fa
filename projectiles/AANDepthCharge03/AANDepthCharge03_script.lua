-- Depth Charge Script
local ADepthChargeProjectile = import("/lua/aeonprojectiles.lua").ADepthChargeProjectile
local VisionMarkerOpti = import("/lua/sim/vizmarker.lua").VisionMarkerOpti

AANDepthCharge03 = ClassProjectile(ADepthChargeProjectile) {

    OnCreate = function(self)
        ADepthChargeProjectile.OnCreate(self)
    end,

    OnImpact = function(self, TargetType, TargetEntity)
        local px,_,pz = self:GetPositionXYZ()
        local marker = VisionMarkerOpti({Owner = self})
        marker:UpdatePosition(px,pz)
        marker:UpdateDuration(5)
        marker:UpdateIntel(self.Army, 5, 'Vision', true)
        ADepthChargeProjectile.OnImpact(self, TargetType, TargetEntity)
    end,

    ---@param self TANAnglerTorpedo06
    OnEnterWater = function(self)
        ADepthChargeProjectile.OnEnterWater(self)

        -- set the magnitude of the velocity to something tiny to really make that water
        -- impact slow it down. We need this to prevent torpedo's striking the bottom
        -- of a shallow pond, like in setons
        self:SetVelocity(0)
        self:SetAcceleration(0.5)
    end,

    --- Adjusted movement thread to gradually speed up the torpedo. It needs to slowly speed
    --- up to prevent it from hitting the floor in relative undeep water
    ---@param self TANAnglerTorpedo06
    MovementThread = function(self)
        WaitTicks(1)
        for k = 1, 6 do
            WaitTicks(1)
            if not IsDestroyed(self) then
                self:SetAcceleration(k)
            else
                break
            end
        end
    end,
}
TypeClass = AANDepthCharge03
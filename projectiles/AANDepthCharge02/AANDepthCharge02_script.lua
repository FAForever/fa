local ADepthChargeProjectile = import("/lua/aeonprojectiles.lua").ADepthChargeProjectile
local VisionMarkerOpti = import("/lua/sim/vizmarker.lua").VisionMarkerOpti

-- Depth Charge Script
---@class AANDepthCharge02 : ADepthChargeProjectile
AANDepthCharge02 = ClassProjectile(ADepthChargeProjectile) {

    ---@param self AANDepthCharge02
    ---@param TargetType string
    ---@param TargetEntity Prop|Unit
    OnImpact = function(self, TargetType, TargetEntity)
        local px,_,pz = self:GetPositionXYZ()
        local marker = VisionMarkerOpti({Owner = self})
        marker:UpdatePosition(px,pz)
        marker:UpdateDuration(5)
        marker:UpdateIntel(self.Army, 5, 'Vision', true)
        ADepthChargeProjectile.OnImpact(self, TargetType, TargetEntity)
    end,
}
TypeClass = AANDepthCharge02
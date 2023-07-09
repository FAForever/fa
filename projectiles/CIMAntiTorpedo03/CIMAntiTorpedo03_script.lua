local CDepthChargeProjectile = import("/lua/cybranprojectiles.lua").CDepthChargeProjectile

-- Ship-based Anti-Torpedo Script
---@class CIMAntiTorpedo02 : CDepthChargeProjectile
CIMAntiTorpedo02 = ClassProjectile(CDepthChargeProjectile) {

    ---@param self CIMAntiTorpedo02
    ---@param inWater? boolean
    OnCreate = function(self, inWater)
        CDepthChargeProjectile.OnCreate(self, inWater)
        self:SetBallisticAcceleration(2)
    end,
}
TypeClass = CIMAntiTorpedo02
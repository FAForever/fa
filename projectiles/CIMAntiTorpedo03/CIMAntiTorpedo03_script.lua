-- Ship-based Anti-Torpedo Script
local CDepthChargeProjectile = import("/lua/cybranprojectiles.lua").CDepthChargeProjectile
CIMAntiTorpedo02 = ClassProjectile(CDepthChargeProjectile) {
	OnCreate = function(self, inWater)
        CDepthChargeProjectile.OnCreate(self, inWater)
        self:SetBallisticAcceleration(2)
    end,
}
TypeClass = CIMAntiTorpedo02
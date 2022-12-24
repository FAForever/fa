--
-- Ship-based Anti-Torpedo Script
--
local CDepthChargeProjectile = import("/lua/cybranprojectiles.lua").CDepthChargeProjectile
CIMAntiTorpedo02 = Class(CDepthChargeProjectile) {

	OnCreate = function(self, inWater)
        CDepthChargeProjectile.OnCreate(self, inWater)
        self:SetBallisticAcceleration(0)
        self.Trash:Add(ForkThread( self.MotionThread,self))
    end,

    MotionThread = function(self)
        WaitSeconds( 2 )
        self:SetBallisticAcceleration(-3)
    end,
}
TypeClass = CIMAntiTorpedo02
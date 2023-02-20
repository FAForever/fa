-- Ship-based Anti-Torpedo Script
local CDepthChargeProjectile = import("/lua/cybranprojectiles.lua").CDepthChargeProjectile
CIMAntiTorpedo02 = ClassProjectile(CDepthChargeProjectile) {

	OnCreate = function(self, inWater)
        CDepthChargeProjectile.OnCreate(self, inWater)
        self:SetBallisticAcceleration(0)
        self.Trash:Add(ForkThread( self.MotionThread,self))
    end,

    MotionThread = function(self)
        WaitTicks(21)
        self:SetBallisticAcceleration(-3)
    end,
}
TypeClass = CIMAntiTorpedo02
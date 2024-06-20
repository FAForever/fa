local CDepthChargeProjectile = import("/lua/cybranprojectiles.lua").CDepthChargeProjectile

--- Ship-based Anti-Torpedo Script
---@class CIMAntiTorpedo02 : CDepthChargeProjectile
CIMAntiTorpedo02 = ClassProjectile(CDepthChargeProjectile) {

    ---@param self CIMAntiTorpedo02
    ---@param inWater boolean
	OnCreate = function(self, inWater)
        CDepthChargeProjectile.OnCreate(self, inWater)
        self:SetBallisticAcceleration(0)
        self.Trash:Add(ForkThread( self.MotionThread,self))
    end,

    ---@param self CIMAntiTorpedo02
    MotionThread = function(self)
        WaitTicks(21)
        self:SetBallisticAcceleration(-3)
    end,
}
TypeClass = CIMAntiTorpedo02
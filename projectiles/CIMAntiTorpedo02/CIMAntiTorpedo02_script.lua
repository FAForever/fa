local CDepthChargeProjectile = import("/lua/cybranprojectiles.lua").CDepthChargeProjectile

-- upvalue for performance
local ForkThread = ForkThread
local TrashBagAdd = TrashBag.Add
local WaitTicks = WaitTicks

--- Ship-based Anti-Torpedo Script
---@class CIMAntiTorpedo02 : CDepthChargeProjectile
CIMAntiTorpedo02 = ClassProjectile(CDepthChargeProjectile) {

    ---@param self CIMAntiTorpedo02
    ---@param inWater boolean
	OnCreate = function(self, inWater)
        CDepthChargeProjectile.OnCreate(self, inWater)
        self:SetBallisticAcceleration(0)
        local trash = self.Trash
        TrashBagAdd(trash,ForkThread( self.MotionThread,self))
    end,

    ---@param self CIMAntiTorpedo02
    MotionThread = function(self)
        WaitTicks(21)
        self:SetBallisticAcceleration(-3)
    end,
}
TypeClass = CIMAntiTorpedo02
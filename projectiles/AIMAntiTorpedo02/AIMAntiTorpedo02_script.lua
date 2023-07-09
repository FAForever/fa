local ATorpedoSubProjectile = import("/lua/aeonprojectiles.lua").QuasarAntiTorpedoChargeSubProjectile

-- Ship-based Anti-Torpedo Script
---@class AIMAntiTorpedo02: ATorpedoSubProjectile
AIMAntiTorpedo02 = ClassProjectile(ATorpedoSubProjectile) 
{
    ---@param self AIMAntiTorpedo02
    OnLostTarget = function(self)
        --Slow this thing down and make it start moving downward.
        self:SetBallisticAcceleration(-0.25)
        self:SetBallisticAcceleration(0,-9.5,0)
    end,
}
TypeClass = AIMAntiTorpedo02
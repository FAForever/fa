local QuasarAntiTorpedoChargeSubProjectile = import("/lua/aeonprojectiles.lua").QuasarAntiTorpedoChargeSubProjectile

-- Ship-based Anti-Torpedo Script
---@class AIMAntiTorpedo01 : QuasarAntiTorpedoChargeSubProjectile
AIMAntiTorpedo01 = ClassProjectile(QuasarAntiTorpedoChargeSubProjectile) {

    ---@param self AIMAntiTorpedo01
    OnLostTarget = function(self)
        self:SetAcceleration(-3.6)
        self:SetLifetime(0.5)
    end,
}
TypeClass = AIMAntiTorpedo01
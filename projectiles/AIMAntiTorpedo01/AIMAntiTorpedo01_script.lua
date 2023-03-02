--
-- Ship-based Anti-Torpedo Script
--
local QuasarAntiTorpedoChargeSubProjectile = import("/lua/aeonprojectiles.lua").ATorpedoSubProjectile

AIMAntiTorpedo01 = Class(QuasarAntiTorpedoChargeSubProjectile) {
    OnLostTarget = function(self)
        self:SetAcceleration(-3.6)
        self:SetLifetime(0.5)
    end,
}

TypeClass = AIMAntiTorpedo01
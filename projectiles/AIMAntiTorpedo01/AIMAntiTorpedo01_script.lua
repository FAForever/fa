-- Automatically upvalued moho functions for performance
local ProjectileMethods = _G.moho.projectile_methods
local ProjectileMethodsSetLifetime = ProjectileMethods.SetLifetime
-- End of automatically upvalued moho functions

#
# Ship-based Anti-Torpedo Script
#
local QuasarAntiTorpedoChargeSubProjectile = import('/lua/aeonprojectiles.lua').ATorpedoSubProjectile

AIMAntiTorpedo01 = Class(QuasarAntiTorpedoChargeSubProjectile)({
    OnLostTarget = function(self)
        self:SetAcceleration(-3.6)
        ProjectileMethodsSetLifetime(self, 0.5)
    end,
})

TypeClass = AIMAntiTorpedo01
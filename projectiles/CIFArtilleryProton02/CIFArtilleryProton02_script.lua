--
-- Cybran T3 Static Artillery Projectile : urb2302
--

local RandomFloat = import("/lua/utilities.lua").GetRandomFloat
local CArtilleryProtonProjectile = import("/lua/cybranprojectiles.lua").CArtilleryProtonProjectile

CIFArtilleryProton02 = Class(CArtilleryProtonProjectile) {
    FxLandHitScale = 1.1,
    FxPropHitScale = 1.1,
    FxUnitHitScale = 1.1,
    
    OnImpact = function(self, targetType, targetEntity)       
        CArtilleryProtonProjectile.OnImpact(self, targetType, targetEntity)

        -- from the north to the east!
        self:ShakeCamera( 20, 2, 0, 1 )
    end,
}
TypeClass = CIFArtilleryProton02
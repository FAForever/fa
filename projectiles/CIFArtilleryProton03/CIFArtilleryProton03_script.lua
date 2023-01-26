--
-- Cybran Scathis Projectile : url0401
--

local RandomFloat = import("/lua/utilities.lua").GetRandomFloat
local CArtilleryProtonProjectile = import("/lua/cybranprojectiles.lua").CArtilleryProtonProjectile

CIFArtilleryProton03 = Class(CArtilleryProtonProjectile) {
    FxLandHitScale = 1.6,
    FxPropHitScale = 1.6,
    FxUnitHitScale = 1.6,
    
    OnImpact = function(self, targetType, targetEntity)       
        CArtilleryProtonProjectile.OnImpact(self, targetType, targetEntity)

        -- from the east to the west!
        self:ShakeCamera( 20, 3, 0, 1 )
    end,
}
TypeClass = CIFArtilleryProton03
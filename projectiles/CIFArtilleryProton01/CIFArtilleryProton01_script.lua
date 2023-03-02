--
-- Cybran T3 Mobile Artillery Projectile : url0304
--

local RandomFloat = import("/lua/utilities.lua").GetRandomFloat
local CArtilleryProtonProjectile = import("/lua/cybranprojectiles.lua").CArtilleryProtonProjectile

CIFArtilleryProton01 = Class(CArtilleryProtonProjectile) {
    FxLandHitScale = 0.65,
    FxPropHitScale = 0.65,
    FxUnitHitScale = 0.65,
    
    OnImpact = function(self, targetType, targetEntity)
        CArtilleryProtonProjectile.OnImpact(self, targetType, targetEntity)

        -- shake it diagonal too!
        self:ShakeCamera( 20, 1, 0, 1 )
    end,
}
TypeClass = CIFArtilleryProton01
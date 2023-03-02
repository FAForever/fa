--
-- UEF T3 Mobile Artillery Anti-Matter Shells : uel0304
--

local RandomFloat = import("/lua/utilities.lua").GetRandomFloat
local TArtilleryAntiMatterSmallProjectile = import("/lua/terranprojectiles.lua").TArtilleryAntiMatterSmallProjectile
TIFAntiMatterShells02 = Class(TArtilleryAntiMatterSmallProjectile) {
    OnImpact = function(self, targetType, targetEntity)
        TArtilleryAntiMatterSmallProjectile.OnImpact(self, targetType, targetEntity)

        -- woop!
        self:ShakeCamera( 20, 1, 0, 1 )
    end,
}

TypeClass = TIFAntiMatterShells02
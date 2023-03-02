--
-- UEF Anti-Matter Shells
--

local RandomFloat = import("/lua/utilities.lua").GetRandomFloat
local TArtilleryAntiMatterProjectile = import("/lua/terranprojectiles.lua").TArtilleryAntiMatterProjectile

TIFAntiMatterShells01 = Class(TArtilleryAntiMatterProjectile) {
    FxSplatScale = 9,
    OnImpact = function(self, targetType, targetEntity)
        TArtilleryAntiMatterProjectile.OnImpact(self, targetType, targetEntity)

        -- party hardy!
        self:ShakeCamera(20, 3, 0, 1)
    end,
}

TypeClass = TIFAntiMatterShells01
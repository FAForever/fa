--
-- UEF T3 Artillery Anti-Matter Shells : ueb2302
--

local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local TArtilleryAntiMatterProjectile02 = import('/lua/terranprojectiles.lua').TArtilleryAntiMatterProjectile02
TIFAntiMatterShells01 = Class(TArtilleryAntiMatterProjectile02) {
    FxSplatScale = 7,

    OnImpact = function(self, targetType, targetEntity)
        self:ShakeCamera(20, 2, 0, 1)
        TArtilleryAntiMatterProjectile02.OnImpact(self, targetType, targetEntity)
    end,
}

TypeClass = TIFAntiMatterShells01
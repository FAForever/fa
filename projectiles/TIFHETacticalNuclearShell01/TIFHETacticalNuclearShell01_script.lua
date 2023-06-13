-- UEF Anti-Matter Shells

local TArtilleryAntiMatterProjectile = import("/lua/terranprojectiles.lua").TArtilleryAntiMatterProjectile

TIFAntiMatterShells01 = ClassProjectile(TArtilleryAntiMatterProjectile) {
    FxSplatScale = 9,
    OnImpact = function(self, targetType, targetEntity)
        TArtilleryAntiMatterProjectile.OnImpact(self, targetType, targetEntity)
        self:ShakeCamera(20, 3, 0, 1)
    end,
}TypeClass = TIFAntiMatterShells01
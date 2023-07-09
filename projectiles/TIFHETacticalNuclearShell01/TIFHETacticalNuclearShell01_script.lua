local TArtilleryAntiMatterProjectile = import("/lua/terranprojectiles.lua").TArtilleryAntiMatterProjectile

-- UEF Anti-Matter Shells
---@class TIFAntiMatterShells01 : TArtilleryAntiMatterProjectile
TIFAntiMatterShells01 = ClassProjectile(TArtilleryAntiMatterProjectile) {
    FxSplatScale = 9,

    ---@param self TIFAntiMatterShells01
    ---@param targetType string
    ---@param targetEntity Unit
    OnImpact = function(self, targetType, targetEntity)
        TArtilleryAntiMatterProjectile.OnImpact(self, targetType, targetEntity)
        self:ShakeCamera(20, 3, 0, 1)
    end,
}TypeClass = TIFAntiMatterShells01
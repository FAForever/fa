local TArtilleryAntiMatterSmallProjectile = import("/lua/terranprojectiles.lua").TArtilleryAntiMatterSmallProjectile

-- UEF T3 Mobile Artillery Anti-Matter Shells : uel0304
---@class TIFAntiMatterShells02 : TArtilleryAntiMatterSmallProjectile
TIFAntiMatterShells02 = ClassProjectile(TArtilleryAntiMatterSmallProjectile) {

    ---@param self TIFAntiMatterShells02
    ---@param targetType string
    ---@param targetEntity Unit
    OnImpact = function(self, targetType, targetEntity)
        TArtilleryAntiMatterSmallProjectile.OnImpact(self, targetType, targetEntity)
        self:ShakeCamera( 20, 1, 0, 1 )
    end,
}
TypeClass = TIFAntiMatterShells02
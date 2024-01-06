local CArtilleryProtonProjectile = import("/lua/cybranprojectiles.lua").CArtilleryProtonProjectile

--- Cybran T3 Mobile Artillery Projectile : url0304
---@class CIFArtilleryProton01 : CArtilleryProtonProjectile
CIFArtilleryProton01 = ClassProjectile(CArtilleryProtonProjectile) {
    FxLandHitScale = 0.65,
    FxPropHitScale = 0.65,
    FxUnitHitScale = 0.65,

    ---@param self CIFArtilleryProton01
    ---@param targetType string
    ---@param targetEntity Prop|Unit
    OnImpact = function(self, targetType, targetEntity)
        CArtilleryProtonProjectile.OnImpact(self, targetType, targetEntity)
        self:ShakeCamera( 20, 1, 0, 1 )
    end,
}
TypeClass = CIFArtilleryProton01
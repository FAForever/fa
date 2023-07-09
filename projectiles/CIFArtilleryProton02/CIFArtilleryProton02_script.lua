local CArtilleryProtonProjectile = import("/lua/cybranprojectiles.lua").CArtilleryProtonProjectile

-- Cybran T3 Static Artillery Projectile : urb2302
---@class CIFArtilleryProton02 : CArtilleryProtonProjectile
CIFArtilleryProton02 = ClassProjectile(CArtilleryProtonProjectile) {
    FxLandHitScale = 1.1,
    FxPropHitScale = 1.1,
    FxUnitHitScale = 1.1,

    ---@param self CIFArtilleryProton02
    ---@param targetType string
    ---@param targetEntity Unit
    OnImpact = function(self, targetType, targetEntity)       
        CArtilleryProtonProjectile.OnImpact(self, targetType, targetEntity)
        self:ShakeCamera( 20, 2, 0, 1 )
    end,
}
TypeClass = CIFArtilleryProton02
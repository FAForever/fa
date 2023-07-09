local CArtilleryProtonProjectile = import("/lua/cybranprojectiles.lua").CArtilleryProtonProjectile

-- Cybran Scathis Projectile : url0401
---@class CIFArtilleryProton03 : CArtilleryProtonProjectile
CIFArtilleryProton03 = ClassProjectile(CArtilleryProtonProjectile) {
    FxLandHitScale = 1.6,
    FxPropHitScale = 1.6,
    FxUnitHitScale = 1.6,

    ---@param self CIFArtilleryProton03
    ---@param targetType string
    ---@param targetEntity Unit
    OnImpact = function(self, targetType, targetEntity)       
        CArtilleryProtonProjectile.OnImpact(self, targetType, targetEntity)
        self:ShakeCamera( 20, 3, 0, 1 )
    end,
}
TypeClass = CIFArtilleryProton03
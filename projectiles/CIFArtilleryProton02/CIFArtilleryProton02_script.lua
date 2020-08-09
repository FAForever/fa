--
-- Cybran T3 Static Artillery Projectile : urb2302
--
local CArtilleryProtonProjectile = import('/lua/cybranprojectiles.lua').CArtilleryProtonProjectile

CIFArtilleryProton02 = Class(CArtilleryProtonProjectile) {
    FxLandHitScale = 1.1,
    FxPropHitScale = 1.1,
    FxUnitHitScale = 1.1,
}
TypeClass = CIFArtilleryProton02
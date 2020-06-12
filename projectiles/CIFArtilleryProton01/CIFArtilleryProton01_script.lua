--
-- Cybran T3 Mobile Artillery Projectile : url0304
--
local CArtilleryProtonProjectile = import('/lua/cybranprojectiles.lua').CArtilleryProtonProjectile
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

CIFArtilleryProton01 = Class(CArtilleryProtonProjectile) {
    FxLandHitScale = 0.65,
    FxPropHitScale = 0.65,
    FxUnitHitScale = 0.65,
}
TypeClass = CIFArtilleryProton01
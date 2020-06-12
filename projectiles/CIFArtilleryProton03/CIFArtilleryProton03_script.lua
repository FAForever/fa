--
-- Cybran Scathis Projectile : url0401
--
local CArtilleryProtonProjectile = import('/lua/cybranprojectiles.lua').CArtilleryProtonProjectile
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

CIFArtilleryProton03 = Class(CArtilleryProtonProjectile) {
    FxLandHitScale = 1.6,
    FxPropHitScale = 1.6,
    FxUnitHitScale = 1.6,
}
TypeClass = CIFArtilleryProton03
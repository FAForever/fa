-- UEF Small Yield Nuclear Bomb UEA0304 : uef strategic bomber

-- UEA0304
TIFSmallYieldNuclearBomb01 = Class(import('/lua/terranprojectiles.lua').TIFSmallYieldNuclearBombProjectile) {
	PolyTrail = '/effects/emitters/default_polytrail_04_emit.bp',
	FxLandHitScale = 0.5,
    FxUnitHitScale = 0.5,
}
TypeClass = TIFSmallYieldNuclearBomb01

local TIFSmallYieldNuclearBombProjectile = import("/lua/terranprojectiles.lua").TIFSmallYieldNuclearBombProjectile

--- UEF Small Yield Nuclear Bomb UEA0304 : uef strategic bomber
---@class TIFSmallYieldNuclearBomb01 : TIFSmallYieldNuclearBombProjectile
TIFSmallYieldNuclearBomb01 = ClassProjectile(TIFSmallYieldNuclearBombProjectile) {
	PolyTrail = '/effects/emitters/default_polytrail_04_emit.bp',
	FxLandHitScale = 0.5,
    FxUnitHitScale = 0.5,
}
TypeClass = TIFSmallYieldNuclearBomb01
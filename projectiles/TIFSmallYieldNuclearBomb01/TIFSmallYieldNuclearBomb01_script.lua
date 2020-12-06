#
# UEF Small Yield Nuclear Bomb
#
local TIFSmallYieldNuclearBombProjectile = import('/lua/terranprojectiles.lua').TArtilleryAntiMatterProjectile
TIFSmallYieldNuclearBomb01 = Class(TIFSmallYieldNuclearBombProjectile) {
	PolyTrail = '/effects/emitters/default_polytrail_04_emit.bp',
	FxLandHitScale = 0.5,
    FxUnitHitScale = 0.5,
}

TypeClass = TIFSmallYieldNuclearBomb01
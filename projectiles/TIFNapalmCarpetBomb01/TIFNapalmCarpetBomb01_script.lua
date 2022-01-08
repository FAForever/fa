--
-- Terran Napalm Carpet Bomb
--

local TNapalmCarpetBombProjectile = import('/lua/terranprojectiles.lua').TNapalmCarpetBombProjectile

TIFNapalmCarpetBomb01 = Class(TNapalmCarpetBombProjectile) {
    OnImpact = function(self, targetType, targetEntity)
        DamageRing(self, pos, 0.1, 5/4 * radius, 10, 'Fire', FriendlyFire, false)
		TNapalmCarpetBombProjectile.OnImpact( self, targetType, targetEntity )
    end,
}

TypeClass = TIFNapalmCarpetBomb01

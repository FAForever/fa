--
-- Terran Napalm Carpet Bomb
--

local TNapalmCarpetBombProjectile = import('/lua/terranprojectiles.lua').TNapalmCarpetBombProjectile

TIFNapalmCarpetBomb01 = Class(TNapalmCarpetBombProjectile) {
    OnImpact = function(self, targetType, targetEntity)
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
            local rotation = RandomFloat(0,2*math.pi)
            local radius = self.DamageData.DamageRadius
            local size = radius + RandomFloat(0.75,2.0)
            local pos = self:GetPosition()
            local army = self.Army
            
            DamageRing(self, pos, 0.1, 5/4 * radius, 10, 'Fire', false, false)
            DamageArea(self, pos, radius, 1, 'Force', true)
            DamageArea(self, pos, radius, 1, 'Force', true)
 			CreateDecal(pos, rotation, 'scorch_001_albedo', '', 'Albedo', size, size, 150, 30, army)
		end	 
		TNapalmCarpetBombProjectile.OnImpact( self, targetType, targetEntity )
    end,
}

TypeClass = TIFNapalmCarpetBomb01

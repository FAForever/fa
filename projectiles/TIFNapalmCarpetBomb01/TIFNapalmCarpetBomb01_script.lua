--
-- Terran Napalm Carpet Bomb
--

local TNapalmCarpetBombProjectile = import('/lua/terranprojectiles.lua').TNapalmCarpetBombProjectile

TIFNapalmCarpetBomb01 = Class(TNapalmCarpetBombProjectile) {
    OnImpact = function(self, targetType, targetEntity)

        TNapalmCarpetBombProjectile.OnImpact( self, targetType, targetEntity )

        local pos = self:GetPosition()
        local radius = self.DamageData.DamageRadius
        local FriendlyFire = self.DamageData.DamageFriendly and radius ~=0
        
        DamageArea( self, pos, 0.5 * radius, 1, 'Force', FriendlyFire )
        
        self.DamageData.DamageAmount = self.DamageData.DamageAmount - 2
        
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
            local rotation = RandomFloat(0,2*math.pi)
            local size = radius + RandomFloat(0.75,2.0)
            local army = self.Army
            
            DamageRing(self, pos, 0.1, 3/4 * radius, 10, 'Fire', FriendlyFire, false)
            
 			CreateDecal(pos, rotation, 'scorch_001_albedo', '', 'Albedo', size, size, 150, 30, army)
		end	 

    end,
}

TypeClass = TIFNapalmCarpetBomb01

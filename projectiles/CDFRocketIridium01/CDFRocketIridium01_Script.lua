--
-- Cybran Anti Air Missile : URA0203 : cybran T2 gunship
--

local CIridiumRocketProjectile = import('/lua/cybranprojectiles.lua').CIridiumRocketProjectile

CDFRocketIridium01 = Class(CIridiumRocketProjectile) {
    OnImpact = function(self, targetType, targetEntity)
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
            local rotation = RandomFloat(0,2*math.pi)
            local radius = self.DamageData.DamageRadius
            local pos = self:GetPosition()
            local army = self.Army
            
            DamageArea(self, pos, radius-1, 1, 'Force', true)
            DamageArea(self, pos, radius-1, 1, 'Force', true)
            DamageRing( self, pos, radius, 5/4 * radius, 1, 'Fire', true )
            
            CreateDecal(pos, rotation, 'scorch_001_albedo', '', 'Albedo', radius-0.5, radius-0.5, 100, 50, army)
        end
        
        CIridiumRocketProjectile.OnImpact(self, targetType, targetEntity)
    end,
}

TypeClass = CDFRocketIridium01

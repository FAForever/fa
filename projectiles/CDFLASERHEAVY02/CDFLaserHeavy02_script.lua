--
-- Cybran laser 'bolt' : URB2301 : T2 cyb pd
--

local CHeavyLaserProjectile2 = import('/lua/cybranprojectiles.lua').CHeavyLaserProjectile2

CDFLaserHeavy02 = Class(CHeavyLaserProjectile2) {
    OnImpact = function(self, targetType, targetEntity)
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' and targetType ~= 'Unit' then
            local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
            local rotation = RandomFloat(0,2*math.pi)
            local pos = self:GetPosition()
            local radius = self.DamageData.DamageRadius
            local army = self.Army
            
            DamageArea( self, pos, 0.5, 1, 'Force', true )
            DamageArea( self, pos, 0.5, 1, 'Force', true )
            
            CreateDecal(pos, rotation, 'scorch_001_albedo', '', 'Albedo', 0.5, 0.5, 70, 20, army)
        end

        CHeavyLaserProjectile2.OnImpact(self, targetType, targetEntity)
    end,
}

TypeClass = CDFLaserHeavy02


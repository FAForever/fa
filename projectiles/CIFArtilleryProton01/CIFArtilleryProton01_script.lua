--
-- Cybran T3 Mobile Artillery Projectile : url0304
--

local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local CArtilleryProtonProjectile = import('/lua/cybranprojectiles.lua').CArtilleryProtonProjectile

CIFArtilleryProton01 = Class(CArtilleryProtonProjectile) {
    FxLandHitScale = 0.65,
    FxPropHitScale = 0.65,
    FxUnitHitScale = 0.65,
    
    OnImpact = function(self, targetType, targetEntity)
        local pos = self:GetPosition()
        local radius = self.DamageData.DamageRadius
        local FriendlyFire = self.DamageData.DamageFriendly
        
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )

        self.DamageData.DamageAmount = self.DamageData.DamageAmount - 2
        
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local army = self.Army
            
            CreateDecal( pos, RandomFloat(0.0,6.28), 'scorch_011_albedo', '', 'Albedo', radius * 2, radius * 2, 200, 150, army )
        end
        
        self:ShakeCamera( 20, 1, 0, 1 )
        
        CArtilleryProtonProjectile.OnImpact(self, targetType, targetEntity)
    end,
}
TypeClass = CIFArtilleryProton01
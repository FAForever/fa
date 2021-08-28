--
-- Cybran Scathis Projectile : url0401
--

local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local CArtilleryProtonProjectile = import('/lua/cybranprojectiles.lua').CArtilleryProtonProjectile

CIFArtilleryProton03 = Class(CArtilleryProtonProjectile) {
    FxLandHitScale = 1.6,
    FxPropHitScale = 1.6,
    FxUnitHitScale = 1.6,
    
    OnImpact = function(self, targetType, targetEntity)
        local pos = self:GetPosition()
        local radius = self.DamageData.DamageRadius
        local FriendlyFire = self.DamageData.DamageFriendly
        if radius == 0 then
            local FriendlyFire = false
        end
        
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )

        self.DamageData.DamageAmount = self.DamageData.DamageAmount - 2
        
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local army = self.Army
            
            CreateDecal( pos, RandomFloat(0.0,6.28), 'scorch_011_albedo', '', 'Albedo', radius * 2, radius * 2, 250, 200, army )
        end
        
        self:ShakeCamera( 20, 3, 0, 1 )
        
        CArtilleryProtonProjectile.OnImpact(self, targetType, targetEntity)
    end,
}
TypeClass = CIFArtilleryProton03
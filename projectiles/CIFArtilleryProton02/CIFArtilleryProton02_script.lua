--
-- Cybran T3 Static Artillery Projectile : urb2302
--

local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local CArtilleryProtonProjectile = import('/lua/cybranprojectiles.lua').CArtilleryProtonProjectile

CIFArtilleryProton02 = Class(CArtilleryProtonProjectile) {
    FxLandHitScale = 1.1,
    FxPropHitScale = 1.1,
    FxUnitHitScale = 1.1,
    
    OnImpact = function(self, targetType, targetEntity)
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local pos = self:GetPosition()
            local army = self.Army
            local radius = self.DamageData.DamageRadius
            
            CreateDecal( pos, RandomFloat(0.0,6.28), 'scorch_011_albedo', '', 'Albedo', radius * 2, radius * 2, 250, 200, army )
        end
        
        self:ShakeCamera( 20, 2, 0, 1 )
        
        CArtilleryProtonProjectile.OnImpact(self, targetType, targetEntity)
    end,
}
TypeClass = CIFArtilleryProton02
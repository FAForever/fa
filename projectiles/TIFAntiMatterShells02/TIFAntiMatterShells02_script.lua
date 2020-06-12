--
-- UEF T3 Mobile Artillery Anti-Matter Shells : uel0304
--
local TArtilleryAntiMatterProjectile = import('/lua/terranprojectiles.lua').TArtilleryAntiMatterSmallProjectile
TIFAntiMatterShells02 = Class(TArtilleryAntiMatterProjectile) {
    OnImpact = function(self, targetType, targetEntity)
    
        local pos = self:GetPosition()
        local radius = self.DamageData.DamageRadius
        
        if targetType != 'Shield' and targetType != 'Water' and targetType != 'UnitAir' then
            DamageArea( self, pos, radius, 1, 'Force', true )
            DamageArea( self, pos, radius, 1, 'Force', true )
        end
        
        TArtilleryAntiMatterProjectile.OnImpact(self, targetType, targetEntity)
    end,
}

TypeClass = TIFAntiMatterShells02
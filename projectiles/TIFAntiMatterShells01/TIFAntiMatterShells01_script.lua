--
-- UEF T3 Artillery Anti-Matter Shells : ueb2302
--
local TArtilleryAntiMatterProjectile = import('/lua/terranprojectiles.lua').TArtilleryAntiMatterProjectile02
TIFAntiMatterShells01 = Class(TArtilleryAntiMatterProjectile) {
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

TypeClass = TIFAntiMatterShells01
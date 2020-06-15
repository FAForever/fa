--
-- Aeon T1 Artillery Mortar : ual0103
--
local AArtilleryProjectile = import('/lua/aeonprojectiles.lua').AArtilleryProjectile
local EffectTemplate = import('/lua/EffectTemplates.lua')

AIFMortar01 = Class(AArtilleryProjectile) {
    OnImpact = function(self, targetType, targetEntity)
        if targetType ~= 'Water' and targetType ~= 'UnitAir' and targetType ~= 'Shield' then
            local pos = self:GetPosition()
            local radius = self.DamageData.DamageRadius
            
            DamageArea( self, pos, radius, 1, 'Force', true )
            DamageArea( self, pos, radius, 1, 'Force', true )
        end
        
        AArtilleryProjectile.OnImpact(self, targetType, targetEntity)
    end,
    
    FxImpactLand = EffectTemplate.ALightMortarHit01,
    FxImpactProp = EffectTemplate.ALightMortarHit01,
    FxImpactUnit = EffectTemplate.ALightMortarHit01,
}

TypeClass = AIFMortar01


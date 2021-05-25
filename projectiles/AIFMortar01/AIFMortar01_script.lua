--
-- Aeon T1 Artillery Mortar : ual0103
--
local AArtilleryProjectile = import('/lua/aeonprojectiles.lua').AArtilleryProjectile
local EffectTemplate = import('/lua/EffectTemplates.lua')

AIFMortar01 = Class(AArtilleryProjectile) {
    OnImpact = function(self, targetType, targetEntity)
        local pos = self:GetPosition()
        local radius = self.DamageData.DamageRadius
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
            local rotation = RandomFloat(0,2*math.pi)
            local army = self.Army
            
            CreateDecal(pos, rotation, 'crater_radial01_albedo', '', 'Albedo', radius, radius, 100, 10, army)
        end
        DamageArea( self, pos, radius, 1, 'Force', false )
        DamageArea( self, pos, radius, 1, 'Force', false )
        
        AArtilleryProjectile.OnImpact(self, targetType, targetEntity)
    end,
    
    FxImpactLand = EffectTemplate.ALightMortarHit01,
    FxImpactProp = EffectTemplate.ALightMortarHit01,
    FxImpactUnit = EffectTemplate.ALightMortarHit01,
}

TypeClass = AIFMortar01
--
-- Aeon T1 Artillery Mortar : ual0103
--
local AArtilleryProjectile = import('/lua/aeonprojectiles.lua').AArtilleryProjectile
local EffectTemplate = import('/lua/EffectTemplates.lua')

AIFMortar01 = Class(AArtilleryProjectile) {
    OnImpact = function(self, targetType, targetEntity)
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
            local rotation = RandomFloat(0,2*math.pi)
            local pos = self:GetPosition()
            local radius = self.DamageData.DamageRadius
            local army = self.Army
            
            DamageArea( self, pos, radius, 1, 'Force', true )
            DamageArea( self, pos, radius, 1, 'Force', true )
            CreateDecal(pos, rotation, 'crater_radial01_albedo', '', 'Albedo', radius, radius, 100, 10, army)
        end
        
        AArtilleryProjectile.OnImpact(self, targetType, targetEntity)
    end,
    
    FxImpactLand = EffectTemplate.ALightMortarHit01,
    FxImpactProp = EffectTemplate.ALightMortarHit01,
    FxImpactUnit = EffectTemplate.ALightMortarHit01,
}

TypeClass = AIFMortar01


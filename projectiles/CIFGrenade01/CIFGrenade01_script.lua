--
-- Cybran T1 Artillery EMP Grenade : url0103
--
local CArtilleryProjectile = import('/lua/cybranprojectiles.lua').CArtilleryProjectile
local EffectTemplate = import('/lua/EffectTemplates.lua')

CIFGrenade01 = Class(CArtilleryProjectile) {

    OnImpact = function(self, targetType, targetEntity)
        if targetType != 'Shield' and targetType != 'Water' and targetType != 'UnitAir' then
            local pos = self:GetPosition()
            local radius = self.DamageData.DamageRadius
            
            DamageArea( self, pos, radius, 1, 'Force', true )
            DamageArea( self, pos, radius, 1, 'Force', true )
        end
        
        CArtilleryProjectile.OnImpact(self, targetType, targetEntity)
    end,

    FxImpactUnit = EffectTemplate.CEMPGrenadeHit01,
    FxImpactProp = EffectTemplate.CEMPGrenadeHit01,
    FxImpactLand = EffectTemplate.CEMPGrenadeHit01,
}

TypeClass = CIFGrenade01
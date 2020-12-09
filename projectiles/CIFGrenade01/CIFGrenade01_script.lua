--
-- Cybran T1 Artillery EMP Grenade : url0103
--
local CArtilleryProjectile = import('/lua/cybranprojectiles.lua').CArtilleryProjectile
local EffectTemplate = import('/lua/EffectTemplates.lua')

CIFGrenade01 = Class(CArtilleryProjectile) {

    OnImpact = function(self, targetType, targetEntity)
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
            local rotation = RandomFloat(0,2*math.pi)
            local pos = self:GetPosition()
            local radius = self.DamageData.DamageRadius
            local army = self.Army
            
            DamageArea( self, pos, radius, 1, 'Force', true )
            DamageArea( self, pos, radius, 1, 'Force', true )
            CreateDecal(pos, rotation, 'nuke_scorch_002_albedo', '', 'Albedo', radius, radius, 100, 10, army)

        end
        
        CArtilleryProjectile.OnImpact(self, targetType, targetEntity)
    end,

    FxImpactUnit = EffectTemplate.CEMPGrenadeHit01,
    FxImpactProp = EffectTemplate.CEMPGrenadeHit01,
    FxImpactLand = EffectTemplate.CEMPGrenadeHit01,
}

TypeClass = CIFGrenade01
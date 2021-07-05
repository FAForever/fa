--
-- Cybran T1 Artillery EMP Grenade : url0103
--
local CArtilleryProjectile = import('/lua/cybranprojectiles.lua').CArtilleryProjectile
local EffectTemplate = import('/lua/EffectTemplates.lua')

CIFGrenade01 = Class(CArtilleryProjectile) {

    OnImpact = function(self, targetType, targetEntity)
        local pos = self:GetPosition()
        local radius = self.DamageData.DamageRadius
        local FriendlyFire = self.DamageData.DamageFriendly
        
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )
        
        self.DamageData.DamageAmount = self.DamageData.DamageAmount - 2

        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
            local rotation = RandomFloat(0,2*math.pi)
            local army = self.Army
            
            CreateDecal(pos, rotation, 'nuke_scorch_002_albedo', '', 'Albedo', radius, radius, 100, 10, army)
        end

        CArtilleryProjectile.OnImpact(self, targetType, targetEntity)
    end,

    FxImpactUnit = EffectTemplate.CEMPGrenadeHit01,
    FxImpactProp = EffectTemplate.CEMPGrenadeHit01,
    FxImpactLand = EffectTemplate.CEMPGrenadeHit01,
}

TypeClass = CIFGrenade01
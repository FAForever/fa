local CIridiumRocketProjectile = import('/lua/cybranprojectiles.lua').CIridiumRocketProjectile
CDFRocketIridium03 = Class(CIridiumRocketProjectile) {

    FxImpactUnit = import('/lua/EffectTemplates.lua').CNeutronClusterBombHitUnit01,
    FxImpactProp = import('/lua/EffectTemplates.lua').CNeutronClusterBombHitUnit01,
    FxImpactLand = import('/lua/EffectTemplates.lua').CNeutronClusterBombHitLand01,
    FxImpactWater = import('/lua/EffectTemplates.lua').CNeutronClusterBombHitWater01,

    OnImpact = function(self, targetType, targetEntity)
        CIridiumRocketProjectile.OnImpact(self, targetType, targetEntity)
        local army = self:GetArmy()
        CreateLightParticle( self, -1, army, 2, 1, 'glow_03', 'ramp_red_06' )
        CreateLightParticle( self, -1, army, 1, 3, 'glow_03', 'ramp_antimatter_02' )
        if targetType == 'Shield' then
            Damage(
                self,
                {0,0,0},
                targetEntity,
                self.Data,
                'Normal'
            )
        end
    end,
}

TypeClass = CDFRocketIridium03

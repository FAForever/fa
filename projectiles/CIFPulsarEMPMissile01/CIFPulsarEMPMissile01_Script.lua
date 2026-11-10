local CIridiumRocketProjectile = import('/lua/cybranprojectiles.lua').CIridiumRocketProjectile
CDFRocketIridium03 = Class(CIridiumRocketProjectile) {

    FxImpactUnit = import('/lua/effecttemplates.lua').CNeutronClusterBombHitUnit01,
    FxImpactProp = import('/lua/effecttemplates.lua').CNeutronClusterBombHitUnit01,
    FxImpactLand = import('/lua/effecttemplates.lua').CNeutronClusterBombHitLand01,
    FxImpactWater = import('/lua/effecttemplates.lua').CNeutronClusterBombHitWater01,

    OnImpact = function(self, targetType, targetEntity)
        CIridiumRocketProjectile.OnImpact(self, targetType, targetEntity)
        local army = self:GetArmy()
        CreateLightParticle( self, -1, army, 2, 1, 'glow_03', 'ramp_red_06' )
        CreateLightParticle( self, -1, army, 1, 3, 'glow_03', 'ramp_antimatter_02' )
    end,
}

TypeClass = CDFRocketIridium03

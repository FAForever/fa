#
# Cybran Artillery Projectile
#
local CArtilleryProtonProjectile = import('/lua/cybranprojectiles.lua').CArtilleryProtonProjectile
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

CIFArtilleryProton01 = Class(CArtilleryProtonProjectile) {

    OnImpact = function(self, targetType, targetEntity)
        CArtilleryProtonProjectile.OnImpact(self, targetType, targetEntity)
        local army = self.Army
        CreateLightParticle( self, -1, army, 12, 12, 'glow_03', 'ramp_red_06' )
        CreateLightParticle( self, -1, army, 12, 22, 'glow_03', 'ramp_antimatter_02' )
		if targetType == 'Terrain' or targetType == 'Prop' then
			CreateDecal( self:GetPosition(), RandomFloat(0.0,6.28), 'scorch_011_albedo', '', 'Albedo', 14, 14, 350, 200, army )  
        end
        ForkThread(self.ForceThread, self, self:GetPosition())
        self:ShakeCamera( 20, 3, 0, 1 )
    end,
    
    ForceThread = function(self, pos)
        DamageArea(self, pos, 7, 1, 'Force', true)
        WaitTicks(2)
        DamageArea(self, pos, 7, 1, 'Force', true)
        DamageRing(self, pos, 7, 10, 1, 'Fire', true)
    end,
    
    FxLandHitScale = 0.65,
    FxPropHitScale = 0.65,
    FxUnitHitScale = 0.65,
}
TypeClass = CIFArtilleryProton01
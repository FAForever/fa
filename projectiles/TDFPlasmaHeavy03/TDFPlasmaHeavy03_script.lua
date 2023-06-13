--
-- UEF Subcommander Heavy Plasma bolt
--

local THeavyPlasmaCannonProjectile = import("/lua/terranprojectiles.lua").THeavyPlasmaCannonProjectile

TDFPlasmaHeavy03 = ClassProjectile(THeavyPlasmaCannonProjectile) {

    CreateImpactEffects = function( self, army, EffectTable, EffectScale )
		local launcher = self.Launcher
		if launcher and launcher:HasEnhancement( 'HighExplosiveOrdnance' ) then
			CreateLightParticle( self, -1, self.Army, 2.0, 9, 'ring_08', 'ramp_white_03' ) 
			CreateEmitterAtEntity(self,self.Army,'/effects/emitters/terran_subcommander_aoe_01_emit.bp')
		end
		THeavyPlasmaCannonProjectile.CreateImpactEffects( self, army, EffectTable, EffectScale )
	end,
}
TypeClass = TDFPlasmaHeavy03


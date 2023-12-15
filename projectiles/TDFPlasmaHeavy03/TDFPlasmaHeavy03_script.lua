local THeavyPlasmaCannonProjectile = import("/lua/terranprojectiles.lua").THeavyPlasmaCannonProjectile

--- UEF Subcommander Heavy Plasma bolt
---@class TDFPlasmaHeavy03: THeavyPlasmaCannonProjectile
TDFPlasmaHeavy03 = ClassProjectile(THeavyPlasmaCannonProjectile) {

	---@param self TDFPlasmaHeavy03
	---@param army number
	---@param EffectTable table
	---@param EffectScale number
    CreateImpactEffects = function( self, army, EffectTable, EffectScale )
		local launcher = self.Launcher
		local Army = self.Army
		if launcher and launcher:HasEnhancement( 'HighExplosiveOrdnance' ) then
			CreateLightParticle( self, -1, Army, 2.0, 9, 'ring_08', 'ramp_white_03' ) 
			CreateEmitterAtEntity(self, Army,'/effects/emitters/terran_subcommander_aoe_01_emit.bp')
		end
		THeavyPlasmaCannonProjectile.CreateImpactEffects( self, army, EffectTable, EffectScale )
	end,
}
TypeClass = TDFPlasmaHeavy03
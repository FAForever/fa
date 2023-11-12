-- File     :  /data/projectiles/SDFChronatronCannon01/SDFChronatronCannon01_script.lua
-- Author(s):  Gordon Duclos, Greg Kohne
-- Summary  :  Chronatron Cannon Projectile script, XSL0001
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------------------------------
local SChronatronCannon = import("/lua/seraphimprojectiles.lua").SChronatronCannon
local ChronatronBlastAttackAOE = import("/lua/effecttemplates.lua").SChronatronCannonBlastAttackAOE

--- Chronatron Cannon Projectile script, XSL0001
---@class SDFChronatronCannon01 : SChronatronCannon
SDFChronatronCannon01 = ClassProjectile(SChronatronCannon) {
	FxImpactTrajectoryAligned = false,

	---@param self SDFChronatronCannon01
	---@param army number
	---@param EffectTable table
	---@param EffectScale number
    CreateImpactEffects = function( self, army, EffectTable, EffectScale )
		local launcher = self.Launcher
		if launcher and launcher:HasEnhancement( 'BlastAttack' ) then
			for k, v in ChronatronBlastAttackAOE do
				emit = CreateEmitterAtEntity(self,army,v)
			end
		end
		SChronatronCannon.CreateImpactEffects( self, army, EffectTable, EffectScale )
	end,
}
TypeClass = SDFChronatronCannon01
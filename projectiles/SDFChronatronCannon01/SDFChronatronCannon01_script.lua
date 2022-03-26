--****************************************************************************
--**
--**  File     :  /data/projectiles/SDFChronatronCannon01/SDFChronatronCannon01_script.lua
--**  Author(s):  Gordon Duclos, Greg Kohne
--**
--**  Summary  :  Chronatron Cannon Projectile script, XSL0001
--**
--**  Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local SChronatronCannon = import('/lua/seraphimprojectiles.lua').SChronatronCannon
local ChronatronBlastAttackAOE = import('/lua/EffectTemplates.lua').SChronatronCannonBlastAttackAOE 

SDFChronatronCannon01 = Class(SChronatronCannon) {
	FxImpactTrajectoryAligned = false,
	
    CreateImpactEffects = function( self, army, EffectTable, EffectScale )
		local launcher = self:GetLauncher()
		if launcher and launcher:HasEnhancement( 'BlastAttack' ) then
			for k, v in ChronatronBlastAttackAOE do
				emit = CreateEmitterAtEntity(self,army,v)
			end
		end
		SChronatronCannon.CreateImpactEffects( self, army, EffectTable, EffectScale )
	end,
}
TypeClass = SDFChronatronCannon01
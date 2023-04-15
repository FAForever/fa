-- File     :  /data/projectiles/BrackmanQAIHackCircuitryEffect02/BrackmanQAIHackCircuitryEffect02_script.lua
-- Author(s):  Greg Kohne
-- Summary  :  BrackmanQAIHackCircuitryEffect02, non-damaging
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------------------------------------------------
local EffectTemplate = import("/lua/effecttemplates.lua")
local EmitterProjectile = import("/lua/sim/defaultprojectiles.lua").EmitterProjectile

BrackmanQAIHackCircuitryEffect02 = Class(EmitterProjectile) {
	FxImpactTrajectoryAligned = true,
	FxTrajectoryAligned= true,
	FxTrails = EffectTemplate.CBrackmanQAIHackCircuitryEffectFxtrailsALL[2],
}
TypeClass = BrackmanQAIHackCircuitryEffect02
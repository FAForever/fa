-- File     :  /data/projectiles/BrackmanQAIHackCircuitryEffect03/BrackmanQAIHackCircuitryEffect03_script.lua
-- Author(s):  Greg Kohne
-- Summary  :  BrackmanQAIHackCircuitryEffect03, non-damaging
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------------------------------------------------
local EffectTemplate = import("/lua/effecttemplates.lua")
local EmitterProjectile = import("/lua/sim/defaultprojectiles.lua").EmitterProjectile

BrackmanQAIHackCircuitryEffect03 = Class(EmitterProjectile) {
	FxImpactTrajectoryAligned = true,
	FxTrajectoryAligned= true,
	FxTrails = EffectTemplate.CBrackmanQAIHackCircuitryEffectFxtrailsALL[3],
}
TypeClass = BrackmanQAIHackCircuitryEffect03

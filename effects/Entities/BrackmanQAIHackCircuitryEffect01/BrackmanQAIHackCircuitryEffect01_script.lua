-- File     :  /data/projectiles/BrackmanQAIHackCircuitryEffect01/BrackmanQAIHackCircuitryEffect01_script.lua
-- Author(s):  Greg Kohne
-- Summary  :  BrackmanQAIHackCircuitryEffect01, non-damaging
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--------------------------------------------------------------------------------------------------------------
local EffectTemplate = import("/lua/effecttemplates.lua")
local EmitterProjectile = import("/lua/sim/defaultprojectiles.lua").EmitterProjectile

--- BrackmanQAIHackCircuitryEffect01, non-damaging
---@class BrackmanQAIHackCircuitryEffect01 : EmitterProjectile
BrackmanQAIHackCircuitryEffect01 = Class(EmitterProjectile) {
	FxImpactTrajectoryAligned = true,
	FxTrajectoryAligned= true,
	FxTrails = EffectTemplate.CBrackmanQAIHackCircuitryEffectFxtrailsALL[1],
}
TypeClass = BrackmanQAIHackCircuitryEffect01
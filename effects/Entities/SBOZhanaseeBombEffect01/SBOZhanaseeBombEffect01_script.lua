--****************************************************************************
--**
--**  File     :  /data/projectiles/SBOZhanaseeBombEffect01/SBOZhanaseeBombEffect01_script.lua
--**  Author(s):  Greg Kohne, Aaron Lundquist
--**
--**  Summary  :  Zhanasee Bomb effect script, non-damaging
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local EffectTemplate = import("/lua/effecttemplates.lua")

SBOZhanaseeBombEffect01 = Class(import("/lua/sim/defaultprojectiles.lua").MultiPolyTrailProjectile) {
	FxTrails = import("/lua/effecttemplates.lua").NoEffects,
	PolyTrails = EffectTemplate.SZhanaseeBombHitSpiralFxPolyTrails,
	PolyTrailOffset = import("/lua/effecttemplates.lua").DefaultPolyTrailOffset1,   
}
TypeClass = SBOZhanaseeBombEffect01

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
	FxTrails = { },
	PolyTrails = EffectTemplate.SZhanaseeBombHitSpiralFxPolyTrails,
	PolyTrailOffset = { 0 },   
}
TypeClass = SBOZhanaseeBombEffect01

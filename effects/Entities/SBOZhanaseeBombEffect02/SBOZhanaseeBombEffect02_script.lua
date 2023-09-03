--****************************************************************************
--**
--**  File     :  /data/projectiles/SBOZhanaseeBombEffect02/SBOZhanaseeBombEffect02_script.lua
--**  Author(s):  Gordon Duclos, Aaron Lundquist
--**
--**  Summary  :  Zhanasee Bomb effect script, non-damaging
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local EffectTemplate = import("/lua/effecttemplates.lua")

SBOZhanaseeBombEffect02 = Class(import("/lua/sim/defaultprojectiles.lua").MultiPolyTrailProjectile) {
	FxTrails = { },
	PolyTrails = EffectTemplate.SZhanaseeBombHitSpiralFxPolyTrails,
	PolyTrailOffset = { 0 },   
}
TypeClass = SBOZhanaseeBombEffect02

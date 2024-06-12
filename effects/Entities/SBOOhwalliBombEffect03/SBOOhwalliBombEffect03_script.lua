------------------------------------------------------------------------------
-- File     :  /data/projectiles/SBOKhamaseenBombEffect03/SBOKhamaseenBombEffect03_script.lua
-- Author(s):  Greg Kohne
-- Summary  :  Ohwalli Strategic Bomb effect script, non-damaging
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------

local EmitterProjectile = import("/lua/sim/defaultprojectiles.lua").EmitterProjectile
local EmitterProjectileOnCreate = EmitterProjectile.OnCreate

--- Ohwalli Strategic Bomb effect script, non-damaging
---@class SBOOhwalliBombEffect03 : EmitterProjectile
SBOOhwalliBombEffect03 = Class(EmitterProjectile) {
	FxTrails = import("/lua/effecttemplates.lua").SOhwalliBombHitRingProjectileFxTrails03,
}
TypeClass = SBOOhwalliBombEffect03
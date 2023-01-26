--****************************************************************************
--**
--**  File     :  /data/projectiles/SBOKhamaseenBombEffect04/SBOKhamaseenBombEffect04_script.lua
--**  Author(s):  Greg Kohne
--**
--**  Summary  :  Ohwalli Strategic Bomb effect script, non-damaging
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local EffectTemplate = import("/lua/effecttemplates.lua")
local RandomInt = import("/lua/utilities.lua").GetRandomInt

SBOOhwalliBombEffect04 = Class(import("/lua/sim/defaultprojectiles.lua").EmitterProjectile) {
	FxTrails = EffectTemplate.SOhwalliBombHitRingProjectileFxTrails04,
}
TypeClass = SBOOhwalliBombEffect04

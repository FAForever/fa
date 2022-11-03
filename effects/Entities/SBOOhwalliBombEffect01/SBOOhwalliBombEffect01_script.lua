--****************************************************************************
--**
--**  File     :  /data/projectiles/SBOOhwalliBombEffect01/SBOOhwalliBombEffect01_script.lua
--**  Author(s):  Greg Kohne, Gordon Duclos
--**
--**  Summary  :  Ohwalli Strategic Bomb effect script, non-damaging
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local EffectTemplate = import("/lua/effecttemplates.lua")

SBOOhwalliBombEffect01 = Class(import("/lua/sim/defaultprojectiles.lua").EmitterProjectile) {
	FxTrails = EffectTemplate.SOhwalliBombPlumeFxTrails01,
}
TypeClass = SBOOhwalliBombEffect01

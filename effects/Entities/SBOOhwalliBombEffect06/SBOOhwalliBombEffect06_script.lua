------------------------------------------------------------------------------
-- File     :  /data/projectiles/SBOKhamaseenBombEffect05/SBOKhamaseenBombEffect05_script.lua
-- Author(s):  Greg Kohne
-- Summary  :  Ohwalli Strategic Bomb effect script, non-damaging
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------
local EffectTemplate = import("/lua/effecttemplates.lua")

---@class SBOOhwalliBombEffect06 : EmitterProjectile
SBOOhwalliBombEffect06 = Class(import("/lua/sim/defaultprojectiles.lua").EmitterProjectile) {
    FxTrails = EffectTemplate.SOhwalliBombHitRingProjectileFxTrails06,
}
TypeClass = SBOOhwalliBombEffect06
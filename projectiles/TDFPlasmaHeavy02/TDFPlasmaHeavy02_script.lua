------------------------------------------------------------------
--
--  File     :  /effects/projectiles/TDFPlasmsaHeavy02/TDFPlasmsaHeavy02_script.lua
--  Author(s):  Gordon Duclos
--
--  Summary  :  UEF Heavy Plasma Cannon projectile, UEA0305
--
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------

local THeavyPlasmaCannonProjectile = import('/lua/terranprojectiles.lua').THeavyPlasmaCannonProjectile
local EffectTemplate = import('/lua/EffectTemplates.lua')

TDFPlasmaHeavy02 = Class(THeavyPlasmaCannonProjectile) {
    FxTrails = EffectTemplate.TPlasmaCannonHeavyMunition02,

}
TypeClass = TDFPlasmaHeavy02


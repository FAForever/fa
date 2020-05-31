-------------------------------------------------------------------------------
--
--  File     :  /data/projectiles/SBOOhwalliStategicBomb01/SBOOhwalliStategicBomb01_script.lua
--  Author(s):  Greg Kohne, Gordon Duclos, Matt Vainio
--
--  Summary  :  Ohwalli-Strategic Bomb script, used on XSA402
--
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------------------
local SOhwalliStrategicBombProjectile = import('/lua/seraphimprojectiles.lua').SOhwalliStrategicBombProjectile

SBOOhwalliStategicBomb01 = Class(SOhwalliStrategicBombProjectile){
    OnImpact = function(self, TargetType, TargetEntity)
        self:CreateProjectile('/effects/entities/SBOOhwalliBombEffectController01/SBOOhwalliBombEffectController01_proj.bp', 0, 0, 0, 0, 0, 0):SetCollision(false)
        SOhwalliStrategicBombProjectile.OnImpact(self, TargetType, TargetEntity) 
    end,
}
TypeClass = SBOOhwalliStategicBomb01

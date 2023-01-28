-- File     :  /data/projectiles/SBOOhwalliStategicBomb01/SBOOhwalliStategicBomb01_script.lua
-- Author(s):  Greg Kohne, Gordon Duclos, Matt Vainio
-- Summary  :  Ohwalli-Strategic Bomb script, used on XSA402
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------------------
local SOhwalliStrategicBombProjectile = import("/lua/seraphimprojectiles.lua").SOhwalliStrategicBombProjectile

SBOOhwalliStategicBomb01 = ClassProjectile(SOhwalliStrategicBombProjectile){
    OnImpact = function(self, targetType, targetEntity)
        SOhwalliStrategicBombProjectile.OnImpact(self, targetType, targetEntity)

        if targetType == "Terrain" or (targetEntity and targetEntity.Layer == "Land") then
            self:CreateProjectile('/effects/entities/SBOOhwalliBombEffectController01/SBOOhwalliBombEffectController01_proj.bp', 0, 0, 0, 0, 0, 0):SetCollision(false)
        end
    end,
}
TypeClass = SBOOhwalliStategicBomb01

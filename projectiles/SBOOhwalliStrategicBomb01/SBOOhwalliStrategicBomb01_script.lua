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
    OnImpact = function(self, targetType, targetEntity)
        if targetType ~= 'Water' or targetType ~= 'UnitAir' or targetType ~= 'Shield' then
            local pos = self:GetPosition()
            local radius = self.DamageData.DamageRadius
            
            self:CreateProjectile('/effects/entities/SBOOhwalliBombEffectController01/SBOOhwalliBombEffectController01_proj.bp', 0, 0, 0, 0, 0, 0):SetCollision(false)
            DamageArea( self, pos, radius, 1, 'Force', true )
            DamageArea( self, pos, radius, 1, 'Force', true )   
        end
        SOhwalliStrategicBombProjectile.OnImpact(self, targetType, targetEntity)
    end,
}
TypeClass = SBOOhwalliStategicBomb01

-- Automatically upvalued moho functions for performance
local GlobalMethods = _G
local GlobalMethodsDamageArea = GlobalMethods.DamageArea
-- End of automatically upvalued moho functions

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

SBOOhwalliStategicBomb01 = Class(SOhwalliStrategicBombProjectile)({
    OnImpact = function(self, targetType, targetEntity)
        local pos = self:GetPosition()
        local radius = self.DamageData.DamageRadius
        local FriendlyFire = self.DamageData.DamageFriendly and radius ~= 0

        GlobalMethodsDamageArea(self, pos, radius, 1, 'Force', FriendlyFire)
        GlobalMethodsDamageArea(self, pos, radius, 1, 'Force', FriendlyFire)

        self.DamageData.DamageAmount = self.DamageData.DamageAmount - 2

        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            self:CreateProjectile('/effects/entities/SBOOhwalliBombEffectController01/SBOOhwalliBombEffectController01_proj.bp', 0, 0, 0, 0, 0, 0):SetCollision(false)
        end
        SOhwalliStrategicBombProjectile.OnImpact(self, targetType, targetEntity)
    end,
})
TypeClass = SBOOhwalliStategicBomb01

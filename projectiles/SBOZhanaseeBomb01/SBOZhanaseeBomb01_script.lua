-------------------------------------------------------------------------------
--
--  File     :  /data/projectiles/SBOZhanaseeBomb/SBOZhanaseeBomb01_script.lua
--  Author(s):  Greg Kohne, Gordon Duclos, Aaron Lundquist
--
--  Summary  :  Zhanasee Bomb script, used on XSA0304
--
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------------------
local SZhanaseeBombProjectile = import('/lua/seraphimprojectiles.lua').SZhanaseeBombProjectile
local DefaultExplosion = import('/lua/defaultexplosions.lua')
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

SBOZhanaseeBombProjectile01 = Class(SZhanaseeBombProjectile)({
    OnImpact = function(self, targetType, targetEntity)
        local army = self.Army
        local pos = self:GetPosition()
        local radius = self.DamageData.DamageRadius
        local FriendlyFire = self.DamageData.DamageFriendly and radius ~= 0

        DamageArea(self, pos, radius, 1, 'Force', FriendlyFire)
        DamageArea(self, pos, radius, 1, 'Force', FriendlyFire)

        self.DamageData.DamageAmount = self.DamageData.DamageAmount - 2

        CreateLightParticle(self, -1, army, 26, 5, 'sparkle_white_add_08', 'ramp_white_24')

        -- One initial projectile following same directional path as the original
        self:CreateProjectile('/effects/entities/SBOZhanaseeBombEffect01/SBOZhanaseeBombEffect01_proj.bp', 0, 0, 0, 0, 10.0, 0):SetCollision(false):SetVelocity(0, 10.0, 0)
        self:CreateProjectile('/effects/entities/SBOZhanaseeBombEffect02/SBOZhanaseeBombEffect02_proj.bp', 0, 0, 0, 0, 0.05, 0):SetCollision(false):SetVelocity(0, 0.05, 0)

        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            CreateDecal(pos, RandomFloat(0.0, 6.28), 'Scorch_012_albedo', '', 'Albedo', 40, 40, 300, 200, army)
        end

        SZhanaseeBombProjectile.OnImpact(self, targetType, targetEntity)

    end,
})
TypeClass = SBOZhanaseeBombProjectile01

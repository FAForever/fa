-- File     :  /data/projectiles/SBOZhanaseeBomb/SBOZhanaseeBomb01_script.lua
-- Author(s):  Greg Kohne, Gordon Duclos, Aaron Lundquist
-- Summary  :  Zhanasee Bomb script, used on XSA0304
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------------------
local SZhanaseeBombProjectile = import("/lua/seraphimprojectiles.lua").SZhanaseeBombProjectile

SBOZhanaseeBombProjectile01 = ClassProjectile(SZhanaseeBombProjectile){
    OnImpact = function(self, targetType, targetEntity)        
		SZhanaseeBombProjectile.OnImpact(self, targetType, targetEntity) 
        local army = self.Army
        CreateLightParticle(self, -1, army, 26, 5, 'sparkle_white_add_08', 'ramp_white_24' )

        if targetType == 'Terrain' then
            CreateDecal( self:GetPosition(), Random() * 6.28, 'Scorch_012_albedo', '', 'Albedo', 40, 40, 300, 200, army)
        end

        -- One initial projectile following same directional path as the original
        self:CreateProjectile('/effects/entities/SBOZhanaseeBombEffect01/SBOZhanaseeBombEffect01_proj.bp', 0, 0, 0, 0, 10.0, 0):SetCollision(false):SetVelocity(0,10.0, 0)
        self:CreateProjectile('/effects/entities/SBOZhanaseeBombEffect02/SBOZhanaseeBombEffect02_proj.bp', 0, 0, 0, 0, 0.05, 0):SetCollision(false):SetVelocity(0,0.05, 0)
    end,
}
TypeClass = SBOZhanaseeBombProjectile01

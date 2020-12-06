------------------------------------------------------------
--
--  File     :  /data/projectiles/TDFFragmentationGrenade01/TDFFragmentationGrenade01_script.lua
--  Author(s):  Matt Vainio
--
--  Summary  :  UEF Fragmentation Shells, DEL0204 : mongoose
--
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------

local TFragmentationGrenade = import('/lua/terranprojectiles.lua').TFragmentationGrenade
local DefaultProjectileFile = import('/lua/sim/defaultprojectiles.lua')
local EmitterProjectile = DefaultProjectileFile.EmitterProjectile

TDFFragmentationGrenade01 = Class(TFragmentationGrenade) {
    OnImpact = function(self, targetType, targetEntity)
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
            local rotation = RandomFloat(0,2*math.pi)
            local radius = self.DamageData.DamageRadius
            local pos = self:GetPosition()
            local army = self.Army
            
            DamageArea(self, pos, radius, 1, 'Force', true)
            DamageArea(self, pos, radius, 1, 'Force', true)
            DamageRing( self, pos, radius, 5/4 * radius, 1, 'Fire', true )
            
            CreateDecal(pos, rotation, 'scorch_001_albedo', '', 'Albedo', radius+1, radius+1, 100, 50, army)
        end
        
        EmitterProjectile.OnImpact(self, targetType, targetEntity)
    end,
}

TypeClass = TDFFragmentationGrenade01
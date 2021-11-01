------------------------------------------------------------
--
--  File     :  /data/projectiles/TDFFragmentationGrenade01/TDFFragmentationGrenade01_script.lua
--  Author(s):  Matt Vainio
--
--  Summary  :  UEF Fragmentation Shells, DEL0204 : mongoose
--
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------

-- Automatically upvalued moho functions for performance
local GlobalMethods = _G
local GlobalMethodsCreateDecal = GlobalMethods.CreateDecal
local GlobalMethodsDamageArea = GlobalMethods.DamageArea
local GlobalMethodsDamageRing = GlobalMethods.DamageRing
-- End of automatically upvalued moho functions

local TFragmentationGrenade = import('/lua/terranprojectiles.lua').TFragmentationGrenade
local DefaultProjectileFile = import('/lua/sim/defaultprojectiles.lua')
local EmitterProjectile = DefaultProjectileFile.EmitterProjectile

TDFFragmentationGrenade01 = Class(TFragmentationGrenade)({
    OnImpact = function(self, targetType, targetEntity)
        local pos = self:GetPosition()
        local radius = self.DamageData.DamageRadius
        local FriendlyFire = self.DamageData.DamageFriendly and radius ~= 0

        GlobalMethodsDamageArea(self, pos, radius, 1, 'Force', FriendlyFire)
        GlobalMethodsDamageArea(self, pos, radius, 1, 'Force', FriendlyFire)

        self.DamageData.DamageAmount = self.DamageData.DamageAmount - 2

        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
            local rotation = RandomFloat(0, 2 * math.pi)
            local army = self.Army

            GlobalMethodsDamageRing(self, pos, radius, 5 / 4 * radius, 1, 'Fire', FriendlyFire)

            GlobalMethodsCreateDecal(pos, rotation, 'scorch_001_albedo', '', 'Albedo', radius + 1, radius + 1, 85, 30, army)
        end

        EmitterProjectile.OnImpact(self, targetType, targetEntity)
    end,
})

TypeClass = TDFFragmentationGrenade01
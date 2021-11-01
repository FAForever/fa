------------------------------------------------------------
--
--  File     :  /data/projectiles/CDFRocketIridium02/CDFRocketIridium02_script.lua
--  Author(s):  Matt Vainio
--
--  Summary  :  Cybran Iridium Rocket Tubes, DRL0204 : cyb T2 range bot (hoplite)
--
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------

-- Automatically upvalued moho functions for performance
local GlobalMethods = _G
local GlobalMethodsCreateDecal = GlobalMethods.CreateDecal
local GlobalMethodsDamageArea = GlobalMethods.DamageArea
local GlobalMethodsDamageRing = GlobalMethods.DamageRing
-- End of automatically upvalued moho functions

local CIridiumRocketProjectile = import('/lua/cybranprojectiles.lua').CIridiumRocketProjectile

CDFRocketIridium02 = Class(CIridiumRocketProjectile)({
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

            GlobalMethodsDamageRing(self, pos, radius, 5 / 4 * radius, 1, 'Fire', true)

            GlobalMethodsCreateDecal(pos, rotation, 'scorch_001_albedo', '', 'Albedo', radius + 1, radius + 1, 100, 50, army)
        end

        CIridiumRocketProjectile.OnImpact(self, targetType, targetEntity)
    end,
})

TypeClass = CDFRocketIridium02

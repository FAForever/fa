-- Automatically upvalued moho functions for performance
local EntityMethods = _G.moho.entity_methods
local EntityMethodsShakeCamera = EntityMethods.ShakeCamera

local GlobalMethods = _G
local GlobalMethodsCreateDecal = GlobalMethods.CreateDecal
local GlobalMethodsDamageArea = GlobalMethods.DamageArea
-- End of automatically upvalued moho functions

------------------------------------------------------------
--
--  File     :  /data/projectiles/SIFSuthanusArtilleryShell01/SIFSuthanusArtilleryShell01_script.lua
--  Author(s):  Gordon Duclos, Greg Kohne, Dru Staltman, Aaron Lundquist
--
--  Summary  :  Suthanus Artillery Shell Projectile script
--              Seraphim T3 Mobile Artillery : XSL0304
--
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------
local SSuthanusMobileArtilleryShell = import('/lua/seraphimprojectiles.lua').SSuthanusMobileArtilleryShell

SIFSuthanusArtilleryShell01 = Class(SSuthanusMobileArtilleryShell)({
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

            GlobalMethodsCreateDecal(pos, rotation, 'nuke_scorch_002_albedo', '', 'Albedo', radius * 2.5, radius * 2.5, 200, 150, army)
        end

        EntityMethodsShakeCamera(self, 20, 1, 0, 1)

        SSuthanusMobileArtilleryShell.OnImpact(self, targetType, targetEntity)
    end,
})

TypeClass = SIFSuthanusArtilleryShell01
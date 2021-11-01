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

        DamageArea(self, pos, radius, 1, 'Force', FriendlyFire)
        DamageArea(self, pos, radius, 1, 'Force', FriendlyFire)

        self.DamageData.DamageAmount = self.DamageData.DamageAmount - 2

        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
            local rotation = RandomFloat(0, 2 * math.pi)
            local army = self.Army

            CreateDecal(pos, rotation, 'nuke_scorch_002_albedo', '', 'Albedo', radius * 2.5, radius * 2.5, 200, 150, army)
        end

        self:ShakeCamera(20, 1, 0, 1)

        SSuthanusMobileArtilleryShell.OnImpact(self, targetType, targetEntity)
    end,
})

TypeClass = SIFSuthanusArtilleryShell01
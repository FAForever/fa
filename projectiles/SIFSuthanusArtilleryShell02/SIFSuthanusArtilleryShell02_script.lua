------------------------------------------------------------
--
--  File     :  /data/projectiles/SIFSuthanusArtilleryShell02/SIFSuthanusArtilleryShell02_script.lua
--  Author(s):  Gordon Duclos, Aaron Lundquist
--
--  Summary  :  Suthanus Artillery Shell Projectile script
--              Seraphim T3 Static Artillery : XSB2302
--
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------

local SSuthanusArtilleryShell = import('/lua/seraphimprojectiles.lua').SSuthanusArtilleryShell
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

SIFSuthanusArtilleryShell02 = Class(SSuthanusArtilleryShell) {
    OnImpact = function(self, targetType, targetEntity)
        local pos = self:GetPosition()
        local radius = self.DamageData.DamageRadius
        local FriendlyFire = self.DamageData.DamageFriendly
        if radius == 0 then
            local FriendlyFire = false
        end
        
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )

        self.DamageData.DamageAmount = self.DamageData.DamageAmount - 2
        
        -- if targetType == 'Shield' and self.Data then
            -- DamageArea(self, pos, radius, self.DamageData.DamageAmount, self.DamageData.DamageType, self.DamageData.DamageFriendly)
            -- self.DamageData.DamageAmount = self.Data - self.DamageData.DamageAmount
            -- radius = 0
        -- end
        
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local rotation = RandomFloat(0,2*math.pi)
            local army = self.Army
            
            CreateDecal(pos, rotation, 'crater_radial01_normals', '', 'Alpha Normals', radius+3, radius+3, 250, 200, army)
            CreateDecal(pos, rotation, 'crater_radial01_albedo', '', 'Albedo', radius+7, radius+7, 250, 200, army)
        
        end
        
        self:ShakeCamera(20, 2, 0, 1)

        SSuthanusArtilleryShell.OnImpact(self, targetType, targetEntity)
    end,
}

TypeClass = SIFSuthanusArtilleryShell02
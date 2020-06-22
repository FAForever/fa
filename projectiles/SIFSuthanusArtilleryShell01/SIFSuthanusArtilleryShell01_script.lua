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

SIFSuthanusArtilleryShell01 = Class(SSuthanusMobileArtilleryShell) {
    OnImpact = function(self, targetType, targetEntity)
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'UnitAir' then
            local pos = self:GetPosition()
            local radius = self.DamageData.DamageRadius
            
            DamageArea( self, pos, radius, 1, 'Force', true )
            DamageArea( self, pos, radius, 1, 'Force', true )
        end
        
        SSuthanusMobileArtilleryShell.OnImpact(self, targetType, targetEntity)
    end,
}

TypeClass = SIFSuthanusArtilleryShell01
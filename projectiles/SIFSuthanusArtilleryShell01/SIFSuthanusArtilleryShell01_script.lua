-- File     :  /data/projectiles/SIFSuthanusArtilleryShell01/SIFSuthanusArtilleryShell01_script.lua
-- Author(s):  Gordon Duclos, Greg Kohne, Dru Staltman, Aaron Lundquist
-- Summary  :  Suthanus Artillery Shell Projectile script. Seraphim T3 Mobile Artillery : XSL0304
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------
local SSuthanusMobileArtilleryShell = import("/lua/seraphimprojectiles.lua").SSuthanusMobileArtilleryShell

SIFSuthanusArtilleryShell01 = ClassProjectile(SSuthanusMobileArtilleryShell) {
    OnImpact = function(self, targetType, targetEntity) 
        SSuthanusMobileArtilleryShell.OnImpact(self, targetType, targetEntity)
        self:ShakeCamera( 20, 1, 0, 1 )
    end,
}
TypeClass = SIFSuthanusArtilleryShell01
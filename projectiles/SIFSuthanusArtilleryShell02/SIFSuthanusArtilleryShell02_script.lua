-- File     :  /data/projectiles/SIFSuthanusArtilleryShell02/SIFSuthanusArtilleryShell02_script.lua
-- Author(s):  Gordon Duclos, Aaron Lundquist
-- Summary  :  Suthanus Artillery Shell Projectile script. Seraphim T3 Static Artillery : XSB2302
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------
local SSuthanusArtilleryShell = import("/lua/seraphimprojectiles.lua").SSuthanusArtilleryShell

-- Suthanus Artillery Shell Projectile script. Seraphim T3 Static Artillery : XSB2302
---@class SIFSuthanusArtilleryShell02 : SSuthanusArtilleryShell
SIFSuthanusArtilleryShell02 = ClassProjectile(SSuthanusArtilleryShell) {

    ---@param self SIFSuthanusArtilleryShell02
    ---@param targetType string
    ---@param targetEntity Prop|Unit
    OnImpact = function(self, targetType, targetEntity)
        SSuthanusArtilleryShell.OnImpact(self, targetType, targetEntity)
        self:ShakeCamera(20, 2, 0, 1)
    end,
}
TypeClass = SIFSuthanusArtilleryShell02
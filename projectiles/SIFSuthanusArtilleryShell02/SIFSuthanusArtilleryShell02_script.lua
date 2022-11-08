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

local SSuthanusArtilleryShell = import("/lua/seraphimprojectiles.lua").SSuthanusArtilleryShell
local RandomFloat = import("/lua/utilities.lua").GetRandomFloat

SIFSuthanusArtilleryShell02 = Class(SSuthanusArtilleryShell) {
    OnImpact = function(self, targetType, targetEntity)
        SSuthanusArtilleryShell.OnImpact(self, targetType, targetEntity)

        -- the party started!
        self:ShakeCamera(20, 2, 0, 1)

    end,
}

TypeClass = SIFSuthanusArtilleryShell02
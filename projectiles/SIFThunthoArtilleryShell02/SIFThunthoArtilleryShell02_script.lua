------------------------------------------------------------
--
--  File     :  /data/projectiles/SIFThunthoArtilleryShell01/SIFThunthoArtilleryShell01_script.lua
--  Author(s):  Gordon Duclos, Aaron Lundquist
--
--  Summary  :  Thuntho Artillery Shell Projectile script
--              Seraphim T1 Artillery : XSL0103
--
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------

-- cache for re-using of memory
local VectorCached = Vector(0, 0, 0)

-- upvalue for performance
local Random = Random 
local CreateDecal = CreateDecal

local EntityGetPositionXYZ = _G.moho.entity_methods.GetPositionXYZ

local SThunthoArtilleryShell2 = import("/lua/seraphimprojectiles.lua").SThunthoArtilleryShell2

SIFThunthoArtilleryShell02 = Class(SThunthoArtilleryShell2) { }
TypeClass = SIFThunthoArtilleryShell02
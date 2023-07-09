-- File     :  /data/projectiles/SAAOlarisAAArtillery02/SAAOlarisAAArtillery02_script.lua
-- Author(s):  Gordon Duclos, Aaron Lundquist
-- Summary  :  Olaris AA Artillery Projectile script, XSL0205
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------------------
local SOlarisAAArtillery = import("/lua/seraphimprojectiles.lua").SOlarisAAArtillery

---@class SAAOlarisAAArtillery02: SOlarisAAArtillery    
SAAOlarisAAArtillery02 = ClassProjectile(SOlarisAAArtillery) {}
TypeClass = SAAOlarisAAArtillery02
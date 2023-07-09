-- File     :  /data/projectiles/SAAOlarisAAArtillery05/SAAOlarisAAArtillery05_script.lua
-- Author(s):  Gordon Duclos, Aaron Lundquist
-- Summary  :  Olaris AA Artillery Projectile script, XSS0302
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------------------
local SOlarisAAArtillery = import("/lua/seraphimprojectiles.lua").SOlarisAAArtillery

---@class SAAOlarisAAArtillery05: SOlarisAAArtillery
SAAOlarisAAArtillery05 = ClassProjectile(SOlarisAAArtillery) {}
TypeClass = SAAOlarisAAArtillery05
-- File     :  /data/projectiles/SAAOlarisAAArtillery04/SAAOlarisAAArtillery04_script.lua
-- Author(s):  Gordon Duclos, Aaron Lundquist
-- Summary  :  Olaris AA Artillery Projectile script, XSS0202
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------------------------------
local SOlarisAAArtillery = import("/lua/seraphimprojectiles.lua").SOlarisAAArtillery

---@class SAAOlarisAAArtillery04: SOlarisAAArtillery
SAAOlarisAAArtillery04 = ClassProjectile(SOlarisAAArtillery) {}
TypeClass = SAAOlarisAAArtillery04
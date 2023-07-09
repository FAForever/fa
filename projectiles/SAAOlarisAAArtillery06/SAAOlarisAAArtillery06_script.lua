-- File     :  /data/projectiles/SAAOlarisAAArtillery06/SAAOlarisAAArtillery06_script.lua
-- Author(s):  Gordon Duclos, Aaron Lundquist
-- Summary  :  Olaris AA Artillery Projectile script, XSB2204
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------------------
local SOlarisAAArtillery = import("/lua/seraphimprojectiles.lua").SOlarisAAArtillery

---@class SAAOlarisAAArtillery06: SOlarisAAArtillery
SAAOlarisAAArtillery06 = ClassProjectile(SOlarisAAArtillery) {}
TypeClass = SAAOlarisAAArtillery06
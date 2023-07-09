-- File     :  /data/projectiles/SAAOlarisAAArtillery01/SAAOlarisAAArtillery01_script.lua
-- Author(s):  Gordon Duclos, Aaron Lundquist
-- Summary  :  Olaris AA Artillery Projectile script, XSL0001
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--------------------------------------------------------------------------------------------
local SOlarisAAArtillery = import("/lua/seraphimprojectiles.lua").SOlarisAAArtillery

---@class SAAOlarisAAArtillery01: SOlarisAAArtillery
SAAOlarisAAArtillery01 = ClassProjectile(SOlarisAAArtillery) {}
TypeClass = SAAOlarisAAArtillery01
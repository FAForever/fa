-- File     :  /data/projectiles/SAAOlarisAAArtillery03/SAAOlarisAAArtillery03_script.lua
-- Author(s):  Gordon Duclos, Aaron Lundquist
-- Summary  :  Olaris AA Artillery Projectile script, XSL0401
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--------------------------------------------------------------------------------------------
local SOlarisAAArtillery = import("/lua/seraphimprojectiles.lua").SOlarisAAArtillery

---@class SAAOlarisAAArtillery03: SOlarisAAArtillery
SAAOlarisAAArtillery03 = ClassProjectile(SOlarisAAArtillery) {}
TypeClass = SAAOlarisAAArtillery03
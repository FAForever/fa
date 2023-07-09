-- File     :  /data/projectiles/SAAShleoAAGatlingGun01/SAAShleoAAGatlingGun01_script.lua
-- Author(s):  Gordon Duclos, Greg Kohne, Aaron Lundquist
-- Summary  :  Shleo Gatling Gun Projectile script, XSL0104
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------------------
local SShleoAACannon = import("/lua/seraphimprojectiles.lua").SShleoAACannon

---@class SAAShleoAAGatlingGun01: SShleoAACannon
SAAShleoAAGatlingGun01 = ClassProjectile(SShleoAACannon) {}
TypeClass = SShleoAACannon
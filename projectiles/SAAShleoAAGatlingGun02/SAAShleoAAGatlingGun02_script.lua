-- File     :  /data/projectiles/SAAShleoAAGatlingGun02/SAAShleoAAGatlingGun02_script.lua
-- Author(s):  Gordon Duclos, Aaron Lundquist
-- Summary  :  Shleo Gatling Gun Projectile script, XSA102
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------------------
local SShleoAACannon = import("/lua/seraphimprojectiles.lua").SShleoAACannon

---@class SAAShleoAAGatlingGun02: SShleoAACannon
SAAShleoAAGatlingGun02 = ClassProjectile(SShleoAACannon) {}
TypeClass = SAAShleoAAGatlingGun02
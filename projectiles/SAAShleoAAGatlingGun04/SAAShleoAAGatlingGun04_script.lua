-- File     :  /data/projectiles/SAAShleoAAGatlingGun04/SAAShleoAAGatlingGun04_script.lua
-- Author(s):  Gordon Duclos, Aaron Lundquist
-- Summary  :  Shleo Gatling Gun Projectile script, XSA104
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------------------------------
local SShleoAACannon = import("/lua/seraphimprojectiles.lua").SShleoAACannon

---@class SAAShleoAAGatlingGun04: SShleoAACannon
SAAShleoAAGatlingGun04 = ClassProjectile(SShleoAACannon) {}
TypeClass = SAAShleoAAGatlingGun04
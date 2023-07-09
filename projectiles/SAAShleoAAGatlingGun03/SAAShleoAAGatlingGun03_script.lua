-- File     :  /data/projectiles/SAAShleoAAGatlingGun03/SAAShleoAAGatlingGun03_script.lua
-- Author(s):  Gordon Duclos, Aaron Lundquist
-- Summary  :  Shleo Gatling Gun Projectile script, XSA0202
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------------------------------
local SShleoAACannon = import("/lua/seraphimprojectiles.lua").SShleoAACannon

---@class SAAShleoAAGatlingGun03: SShleoAACannon
SAAShleoAAGatlingGun03 = ClassProjectile(SShleoAACannon) {}
TypeClass = SAAShleoAAGatlingGun03
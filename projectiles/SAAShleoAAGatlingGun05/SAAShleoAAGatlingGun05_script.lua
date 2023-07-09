-- File     :  /data/projectiles/SAAShleoAAGatlingGun05/SAAShleoAAGatlingGun05_script.lua
-- Author(s):  Gordon Duclos, Aaron Lundquist
-- Summary  :  Shleo Gatling Gun Projectile script, XSS0103
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------------------
local SShleoAACannon = import("/lua/seraphimprojectiles.lua").SShleoAACannon

---@class SAAShleoAAGatlingGun05: SShleoAACannon
SAAShleoAAGatlingGun05 = ClassProjectile(SShleoAACannon) {}
TypeClass = SAAShleoAAGatlingGun05
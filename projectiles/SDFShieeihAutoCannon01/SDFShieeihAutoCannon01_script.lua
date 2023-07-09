-- File     :  /data/projectiles/SDFShieeihAutoCannon01/SDFShieeihAutoCannon01_script.lua
-- Author(s): Gordon Duclos, Aaron Lundquist
-- Summary  :  Shie-eih Auto-Cannon Projectile script, XSS0103
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--------------------------------------------------------------------------------------------
local SShriekerAutoCannon = import('/lua/seraphimprojectiles.lua').SShriekerAutoCannon

---@class SDFShieeihAutoCannon01 : SShriekerAutoCannon
SDFShieeihAutoCannon01 = ClassProjectile(SShriekerAutoCannon) {}
TypeClass = SDFShieeihAutoCannon01
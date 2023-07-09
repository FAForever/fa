-- File     :  /data/projectiles/SDFPhasicAutogun01/SDFPhasicAutogun01_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Phasic Autogun Projectile script, XSL0101
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------------
local SPhasicAutogun = import('/lua/seraphimprojectiles.lua').SPhasicAutogun

---@class SDFPhasicAutogun01 : SPhasicAutogun
SDFPhasicAutogun01 = ClassProjectile(SPhasicAutogun) {}
TypeClass = SDFPhasicAutogun01
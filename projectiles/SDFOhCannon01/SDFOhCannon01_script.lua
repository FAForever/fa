-- File     :  /data/projectiles/SDFOhCannon01/SDFOhCannon01_script.lua
-- Author(s):  Gordon Duclos, Aaron Lundquist
-- Summary  :  Oh Spectra Cannon Projectile script, XSL0201
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------------
local SOhCannon = import('/lua/seraphimprojectiles.lua').SOhCannon

---@class SDFOhCannon01 : SOhCannon
SDFOhCannon01 = ClassProjectile(SOhCannon) {}
TypeClass = SDFOhCannon01
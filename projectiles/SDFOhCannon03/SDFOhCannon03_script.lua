-- File     :  /data/projectiles/SDFOhCannon03/SDFOhCannon03_script.lua
-- Author(s):  Gordon Duclos, Aaron Lundquist
-- Summary  :  Oh Spectra Cannon Projectile script, twin-barreled variant, XSB2101
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------------------------
local SOhCannon = import('/lua/seraphimprojectiles.lua').SOhCannon

---@class SDFOhCannon03 : SOhCannon
SDFOhCannon03 = ClassProjectile(SOhCannon) {}
TypeClass = SDFOhCannon03
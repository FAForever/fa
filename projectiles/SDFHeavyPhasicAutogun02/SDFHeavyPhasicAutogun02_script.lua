-- File     :  /data/projectiles/SDFHeavyPhasicAutogun02/SDFHeavyPhasicAutogun02_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Heavy Phasic Autogun Projectile script, XSA0203
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------------------------------
local SHeavyPhasicAutogun02 = import('/lua/seraphimprojectiles.lua').SHeavyPhasicAutogun02

---@class SDFHeavyPhasicAutogun02 : SHeavyPhasicAutogun02
SDFHeavyPhasicAutogun02 = ClassProjectile(SHeavyPhasicAutogun02) {}
TypeClass = SDFHeavyPhasicAutogun02
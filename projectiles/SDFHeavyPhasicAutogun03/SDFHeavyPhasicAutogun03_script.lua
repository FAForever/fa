-- File     :  /data/projectiles/SDFHeavyPhasicAutogun03/SDFHeavyPhasicAutogun03_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Heavy Phasic Autogun Projectile script, XSL0203
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
----------------------------------------------------------------------------------------------
local SHeavyPhasicAutogun = import('/lua/seraphimprojectiles.lua').SHeavyPhasicAutogun

---@class SDFHeavyPhasicAutogun03 : SHeavyPhasicAutogun
SDFHeavyPhasicAutogun03 = ClassProjectile(SHeavyPhasicAutogun) {}
TypeClass = SDFHeavyPhasicAutogun03
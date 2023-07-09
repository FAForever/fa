-- File     :  /data/projectiles/SAABlazarAutoCannon04/SAABlazarAutoCannon04_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Blazar AA AutoCannon Projectile script, XSB2304
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------------------------
local SBlazarAAAutoCannon = import('/lua/seraphimprojectiles.lua').SBlazarAAAutoCannon

---@class SAABlazarAutoCannon04 : SBlazarAAAutoCannon
SAABlazarAutoCannon04 = ClassProjectile(SBlazarAAAutoCannon) {}
TypeClass = SAABlazarAutoCannon04
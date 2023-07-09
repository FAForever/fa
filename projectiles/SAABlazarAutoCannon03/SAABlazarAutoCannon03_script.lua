-- File     :  /data/projectiles/SAABlazarAutoCannon03/SAABlazarAutoCannon03_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Blazar AA AutoCannon Projectile script, XSS0303
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
----------------------------------------------------------------------------------------
local SBlazarAAAutoCannon02 = import('/lua/seraphimprojectiles.lua').SBlazarAAAutoCannon02

---@class SAABlazarAutoCannon03 : SBlazarAAAutoCannon02
SAABlazarAutoCannon03 = ClassProjectile(SBlazarAAAutoCannon02) {}
TypeClass = SAABlazarAutoCannon03
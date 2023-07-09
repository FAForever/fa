-- File     :  /data/projectiles/SAABlazarAutoCannon01/SAABlazarAutoCannon01_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Blazar AA AutoCannon Projectile script, XSA0303
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------------------------------
local SBlazarAAAutoCannon02 = import('/lua/seraphimprojectiles.lua').SBlazarAAAutoCannon02

--- Blazar AA AutoCannon Projectile script, XSA0303
---@class SAABlazarAutoCannon01 : SBlazarAAAutoCannon02
SAABlazarAutoCannon01 = ClassProjectile(SBlazarAAAutoCannon02) {}
TypeClass = SAABlazarAutoCannon01
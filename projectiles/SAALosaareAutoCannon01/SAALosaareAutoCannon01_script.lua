-- File     :  /data/projectiles/SAALosaareAutoCannon01/SAALosaareAutoCannon01_script.lua
-- Author(s):  Greg Kohne, Gordon Duclos
-- Summary  :  Losaare AA AutoCannon Projectile script, XSA0303
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--------------------------------------------------------------------------------------------
local SLosaareAAAutoCannon02 = import('/lua/seraphimprojectiles.lua').SLosaareAAAutoCannon02

---@class SAALosaareAutoCannon01: SLosaareAAAutoCannon02
SAALosaareAutoCannon01 = ClassProjectile(SLosaareAAAutoCannon02) {}
TypeClass = SAALosaareAutoCannon01
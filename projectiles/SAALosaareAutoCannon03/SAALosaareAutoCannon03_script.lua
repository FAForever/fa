-- File     :  /data/projectiles/SAALosaareAutoCannon03/SAALosaareAutoCannon03_script.lua
-- Author(s):  Greg Kohne, Gordon Duclos
-- Summary  :  Losaare AA AutoCannon Projectile script, XSS0303
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------------------
local SLosaareAAAutoCannon02 = import('/lua/seraphimprojectiles.lua').SLosaareAAAutoCannon02

---@class SAALosaareAutoCannon03: SLosaareAAAutoCannon02
SAALosaareAutoCannon03 = ClassProjectile(SLosaareAAAutoCannon02) {}
TypeClass = SAALosaareAutoCannon03
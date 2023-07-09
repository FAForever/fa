--  File     :  /data/projectiles/SAABlazarAutoCannon02/SAABlazarAutoCannon02_script.lua
--  Author(s):  Gordon Duclos
--  Summary  :  Blazar AA AutoCannon Projectile script, XSA0401
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------------
local SBlazarAAAutoCannon = import("/lua/seraphimprojectiles.lua").SBlazarAAAutoCannon

--- Blazar AA AutoCannon Projectile script, XSA0401
---@class SAABlazarAutoCannon02 : SBlazarAAAutoCannon
SAABlazarAutoCannon02 = ClassProjectile(SBlazarAAAutoCannon) {}
TypeClass = SAABlazarAutoCannon02
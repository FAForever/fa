-- File     :  /data/projectiles/SDFAireauWeapon01/SDFAireauWeapon01_script.lua
-- Author(s):  Matt Vainio
-- Summary  :  Aire-Au Autocannon, XSL0401
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------------------
local SDFAireauProjectile = import("/lua/seraphimprojectiles.lua").SDFAireauProjectile

--- Aire-Au Autocannon, XSL0401
---@class SDFAireauWeapon01 : SDFAireauProjectile
SDFAireauWeapon01 = ClassProjectile(SDFAireauProjectile) {}
TypeClass = SDFAireauWeapon01
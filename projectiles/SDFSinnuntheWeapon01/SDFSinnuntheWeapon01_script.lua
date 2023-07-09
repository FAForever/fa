-- File     :  /data/projectiles/SDFSinnuntheWeapon01/SDFSinnuntheWeapon01_script.lua
-- Author(s):  Matt Vainio
-- Summary  :  Sinn-Uthe Projectile script, XSL0401
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------------------------
local SDFSinnuntheWeaponProjectile = import('/lua/seraphimprojectiles.lua').SDFSinnuntheWeaponProjectile

---@class SDFSinnuntheWeapon01 : SDFSinnuntheWeaponProjectile
SDFSinnuntheWeapon01 = ClassProjectile(SDFSinnuntheWeaponProjectile) {}
TypeClass = SDFSinnuntheWeapon01
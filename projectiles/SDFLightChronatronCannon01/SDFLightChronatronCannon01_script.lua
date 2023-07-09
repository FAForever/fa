-- File     :  /data/projectiles/SDFLightChronatronCannon01/SDFLightChronatronCannon01_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Light Chronatron Cannon Projectile script, XSL0301
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------------------------------------------
local SLightChronatronCannon = import('/lua/seraphimprojectiles.lua').SLightChronatronCannon

---@class SDFLightChronatronCannon01 : SLightChronatronCannon
SDFLightChronatronCannon01 = ClassProjectile(SLightChronatronCannon) {}
TypeClass = SDFLightChronatronCannon01
-- File     :  /data/projectiles/SDFTauCannon01/SDFTauCannon01_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Tau Cannon Projectile script, XSL0303
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
----------------------------------------------------------------------------
local STauCannon = import('/lua/seraphimprojectiles.lua').STauCannon

---@class SDFTauCannon01 : STauCannon
SDFTauCannon01 = ClassProjectile(STauCannon) {}
TypeClass = SDFTauCannon01
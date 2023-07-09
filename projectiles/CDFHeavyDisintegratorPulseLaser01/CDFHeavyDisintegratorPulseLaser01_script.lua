------------------------------------------------------------------------------
-- File     :  /data/projectiles/CDFHeavyDisintegratorPulseLaser01/CDFHeavyDisintegratorPulseLaser01_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Cybran Heavy Disintegrator Pulse Laser Projectile script, XRL0305
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------
local CHeavyDisintegratorPulseLaser = import("/lua/cybranprojectiles.lua").CHeavyDisintegratorPulseLaser

---@class CDFHeavyDisintegratorPulseLaser01 : CHeavyDisintegratorPulseLaser
CDFHeavyDisintegratorPulseLaser01 = ClassProjectile(CHeavyDisintegratorPulseLaser) {}
TypeClass = CDFHeavyDisintegratorPulseLaser01
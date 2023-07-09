-- File     :  /data/projectiles/TDFHiroLaser01/TDFHiroLaser01_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  UEF Hiro Laser Projectile script, XES0307
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------------
local THiroLaser = import('/lua/terranprojectiles.lua').THiroLaser

---@class TDFHiroLaser01: THiroLaser    
TDFHiroLaser01 = ClassProjectile(THiroLaser) {}
TypeClass = TDFHiroLaser01
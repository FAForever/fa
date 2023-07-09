-- File     :  /data/projectiles/SDFAireauBolter02/SDFAireauBolter02_script.lua
-- Author(s):  Gordon Duclos, Aaron Lundquist
-- Summary  :  Aire-au Bolter Projectile script, XSL0303
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------------------
local SDFAireauBolter = import('/lua/seraphimprojectiles.lua').SDFAireauBolter

---@class SDFAireauBolter02 : SDFAireauBolter
SDFAireauBolter02 = ClassProjectile(SDFAireauBolter) {}
TypeClass = SDFAireauBolter02
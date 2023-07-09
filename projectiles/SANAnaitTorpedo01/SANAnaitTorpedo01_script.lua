-- File     :  /data/projectiles/SANAnaitTorpedo01/SANAnaitTorpedo01_script.lua
-- Author(s):  Gordon Duclos, Aaron Lundquist
-- Summary  :  Ana-it Torpedo Projectile script, XSS0201
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------------------
local SAnaitTorpedo = import("/lua/seraphimprojectiles.lua").SAnaitTorpedo

---@class SANAnaitTorpedo01: SAnaitTorpedo
SANAnaitTorpedo01 = ClassProjectile(SAnaitTorpedo) {}
TypeClass = SANAnaitTorpedo01
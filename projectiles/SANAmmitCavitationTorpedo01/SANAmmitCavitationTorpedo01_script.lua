-- File     :  /data/projectiles/SANAmmitCavitationTorpedo01/SANAmmitCavitationTorpedo01_script.lua
-- Author(s):  Greg Kohne
-- Summary  :  Seraphim Ammit Torpedo Projectile script, XSB2109
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------------------------------------------
local SAmmitTorpedo = import('/lua/seraphimprojectiles.lua').SAmmitTorpedo

---@class SANAmmitCavitationTorpedo01: SAmmitTorpedo
SANAmmitCavitationTorpedo01 = ClassProjectile(SAmmitTorpedo) {}
TypeClass = SANAmmitCavitationTorpedo01
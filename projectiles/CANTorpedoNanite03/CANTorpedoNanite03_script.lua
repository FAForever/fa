--------------------------------------------------------------------------------
-- File     :  /data/projectiles/CANTorpedoNanite02/CANTorpedoNanite02_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix, Gordon Duclos
-- Summary  :  Cybran Anti-Navy Nanite Torpedo Script Nanite Torpedo releases tiny nanites that do DoT
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--------------------------------------------------------------------------------
local CTorpedoShipProjectile = import("/lua/cybranprojectiles.lua").CTorpedoShipProjectile

---@class CANTorpedoNanite03: CTorpedoShipProjectile
CANTorpedoNanite03 = ClassProjectile(CTorpedoShipProjectile) { }
TypeClass = CANTorpedoNanite03
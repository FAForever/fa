------------------------------------------------------------------------------
-- File     :  /data/projectiles/TANAnglerTorpedo04/TANAnglerTorpedo04_script.lua
-- Author(s):  Matt Vainio
-- Summary  :  Terran Torpedo, XES0102
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------
local TTorpedoSubProjectile = import("/lua/terranprojectiles.lua").TTorpedoSubProjectile

--- Terran Anti Air Missile
---@class TANAnglerTorpedo04: TTorpedoSubProjectile
TANAnglerTorpedo04 = ClassProjectile(TTorpedoSubProjectile) { }
TypeClass = TANAnglerTorpedo04
-- File     :  /data/projectiles/SIMAntiMissile02/SIMAntiMissile02_script.lua
-- Author(s):  Matt Vainio
-- Summary  : Seraphim Electrum Anti Missile
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--------------------------------------------------------------------------------
local SIMAntiMissile = import("/lua/seraphimprojectiles.lua").SIMAntiMissile

-- Seraphim Electrum Anti Missile
---@class SIMAntiMissile02 : SIMAntiMissile
SIMAntiMissile02 = ClassProjectile(SIMAntiMissile) {}
TypeClass = SIMAntiMissile02
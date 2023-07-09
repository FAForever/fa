-- File     :  /data/projectiles/TAARailgun03/TAARailgun03_script.lua
-- Author(s):  Matt Vainio
-- Summary  :  Terran Anti Air basic projectile, DEA0202
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------
local TRailGunProjectile = import('/lua/terranprojectiles.lua').TRailGunProjectile

---@class TAARailgun01 : TRailGunProjectile
TAARailgun01 = ClassProjectile(TRailGunProjectile) {
    FxTrails = import("/lua/effecttemplates.lua").NoEffects,
}
TypeClass = TAARailgun01
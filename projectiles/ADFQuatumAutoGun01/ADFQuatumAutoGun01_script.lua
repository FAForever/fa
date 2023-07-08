--------------------------------------------------------------------------------------
-- File     :  /data/projectiles/ADFQuatumAutoGun01/ADFQuatumAutoGun01_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Aeon Quantum Autogun Projectile script, XAL0203
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--------------------------------------------------------------------------------------
local AQuantumAutogun = import("/lua/aeonprojectiles.lua").AQuantumAutogun

---@class ADFQuatumAutoGun01: AQuantumAutogun
ADFQuatumAutoGun01 = ClassProjectile(AQuantumAutogun) {}
TypeClass = ADFQuatumAutoGun01
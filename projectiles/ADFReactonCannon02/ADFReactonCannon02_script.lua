--------------------------------------------------------------------------------------
-- File     : /data/Projectiles/ADFReactonCannnon02/ADFReactonCannnon02_script.lua
-- Author(s): Gordon Duclos
-- Summary  : Aeon Reacton Cannon Area of Effect Projectile
-- Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--------------------------------------------------------------------------------------
local AReactonCannonAOEProjectile = import("/lua/aeonprojectiles.lua").AReactonCannonAOEProjectile

---@class ADFReactonCannon02: AReactonCannonAOEProjectile
ADFReactonCannon02 = ClassProjectile(AReactonCannonAOEProjectile) {}
TypeClass = ADFReactonCannon02
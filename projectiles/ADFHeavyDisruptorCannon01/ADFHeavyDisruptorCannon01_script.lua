---------------------------------------------------------------------------------------------------
-- File     :  /data/projectiles/ADFHeavyDisruptorCannon01/ADFHeavyDisruptorCannon01_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Aeon Heavy Disruptor Cannon Projectile script, XAL0305
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
----------------------------------------------------------------------------------------------------
local AHeavyDisruptorCannonShell = import('/lua/aeonprojectiles.lua').AHeavyDisruptorCannonShell

---@class ADFHeavyDisruptorCannon01: AHeavyDisruptorCannonShell
ADFHeavyDisruptorCannon01 = ClassProjectile(AHeavyDisruptorCannonShell) {}
TypeClass = ADFHeavyDisruptorCannon01
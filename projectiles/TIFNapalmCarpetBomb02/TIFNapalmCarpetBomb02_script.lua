-------------------------------------------------------------------------------
--
--  File     :  /data/projectiles/TIFNapalmCarpetBomb02/TIFNapalmCarpetBomb02_script.lua
--  Author(s):  Matt Vainio
--
--  Summary  :  Heavy Napalm Bomb, DEA0202
--
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------------------

local TNapalmHvyCarpetBombProjectile = import("/lua/terranprojectiles.lua").TNapalmHvyCarpetBombProjectile

--- Used by dea0202
---@class TIFNapalmCarpetBomb02 : TNapalmHvyCarpetBombProjectile
TIFNapalmCarpetBomb02 = ClassProjectile(TNapalmHvyCarpetBombProjectile) { }

TypeClass = TIFNapalmCarpetBomb02

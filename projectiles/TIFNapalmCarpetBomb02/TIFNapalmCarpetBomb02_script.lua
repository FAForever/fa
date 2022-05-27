-------------------------------------------------------------------------------
--
--  File     :  /data/projectiles/TIFNapalmCarpetBomb02/TIFNapalmCarpetBomb02_script.lua
--  Author(s):  Matt Vainio
--
--  Summary  :  Heavy Napalm Bomb, DEA0202
--
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------------------

-- DEA0202
local TNapalmHvyCarpetBombProjectile = import('/lua/terranprojectiles.lua').TNapalmHvyCarpetBombProjectile

---@class TIFNapalmCarpetBomb02 : TNapalmHvyCarpetBombProjectile
TIFNapalmCarpetBomb02 = Class(TNapalmHvyCarpetBombProjectile) { }

TypeClass = TIFNapalmCarpetBomb02

local EffectTemplate = import('/lua/EffectTemplates.lua')
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

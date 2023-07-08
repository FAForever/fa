----------------------------------------------------------------------------
-- File     :  /data/projectiles/AIFMortar02/AIFMortar02_script.lua
-- Author(s):  Matt Vainio
-- Summary  :  Aeon Mortar, DAB2102
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--------------------------------------------------------------------------
local AIFBallisticMortarProjectile02 = import("/lua/aeonprojectiles.lua").AIFBallisticMortarProjectile02

---@class AIFMortar02 : AIFBallisticMortarProjectile02
AIFMortar02 = ClassProjectile(AIFBallisticMortarProjectile02) {}
TypeClass = AIFMortar02
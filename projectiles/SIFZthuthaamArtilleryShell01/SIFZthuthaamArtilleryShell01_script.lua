-- File     :  /data/projectiles/SIFZthuthaamArtilleryShell01/SIFZthuthaamArtilleryShell01_script.lua
-- Author(s):  Gordon Duclos, Aaron Lundquist
-- Summary  :  Zthuthaam Artillery Shell Projectile script, XSL0301
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--------------------------------------------------------------------------------------------------------
local SZthuthaamArtilleryShell = import("/lua/seraphimprojectiles.lua").SZthuthaamArtilleryShell

---@class SIFZthuthaamArtilleryShell01 : SZthuthaamArtilleryShell
SIFZthuthaamArtilleryShell01 = ClassProjectile(SZthuthaamArtilleryShell) {}
TypeClass = SIFZthuthaamArtilleryShell01
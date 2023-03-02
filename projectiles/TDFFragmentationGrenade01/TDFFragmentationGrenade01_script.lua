------------------------------------------------------------
--
--  File     :  /data/projectiles/TDFFragmentationGrenade01/TDFFragmentationGrenade01_script.lua
--  Author(s):  Matt Vainio
--
--  Summary  :  UEF Fragmentation Shells, DEL0204 : mongoose
--
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------

local TFragmentationGrenade = import("/lua/terranprojectiles.lua").TFragmentationGrenade
local DefaultProjectileFile = import("/lua/sim/defaultprojectiles.lua")
local EmitterProjectile = DefaultProjectileFile.EmitterProjectile

TDFFragmentationGrenade01 = Class(TFragmentationGrenade) { }

TypeClass = TDFFragmentationGrenade01
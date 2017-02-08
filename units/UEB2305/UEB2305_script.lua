-----------------------------------------------------------------
-- File     :  /cdimage/units/UEB2305/UEB2305_script.lua
-- Author(s):  John Comes, David Tomandl
-- Summary  :  UEF Strategic Missile Launcher Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local TStructureUnit = import('/lua/terranunits.lua').TStructureUnit
local TIFStrategicMissileWeapon = import('/lua/terranweapons.lua').TIFStrategicMissileWeapon
local ManualLaunchWeapon = import('/lua/sim/defaultweapons.lua').ManualLaunchWeapon

UEB2305 = Class(TStructureUnit) {
    Weapons = {
        NukeMissiles = Class(TIFStrategicMissileWeapon, ManualLaunchWeapon) {},
    },
}

TypeClass = UEB2305

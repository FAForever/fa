-----------------------------------------------------------------
-- File     :  /cdimage/units/UEB2305/UEB2305_script.lua
-- Author(s):  John Comes, David Tomandl
-- Summary  :  UEF Strategic Missile Launcher Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local TStructureUnit = import("/lua/terranunits.lua").TStructureUnit
local TIFStrategicMissileWeapon = import("/lua/terranweapons.lua").TIFStrategicMissileWeapon

---@class UEB2305 : TStructureUnit
UEB2305 = ClassUnit(TStructureUnit) {
    Weapons = {
        NukeMissiles = ClassWeapon(TIFStrategicMissileWeapon) {},
    },
}

TypeClass = UEB2305

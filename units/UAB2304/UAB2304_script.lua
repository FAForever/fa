---------------------------------------------------------------------------
-- File     :  /cdimage/units/UAB2304/UAB2304_script.lua
-- Author(s):  John Comes, David Tomandl
-- Summary  :  Aeon Advanced Anti-Air System Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------------

local AAmphibiousStructureUnit = import('/lua/aeonunits.lua').AAmphibiousStructureUnit
local AAAZealotMissileWeapon = import('/lua/aeonweapons.lua').AAAZealotMissileWeapon

UAB2304 = Class(AAmphibiousStructureUnit) {
    Weapons = {
        AntiAirMissiles = Class(AAAZealotMissileWeapon) {},
    },
}

TypeClass = UAB2304

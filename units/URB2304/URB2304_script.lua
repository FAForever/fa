---------------------------------------------------------------------------
-- File     :  /cdimage/units/URB2304/URB2304_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix
-- Summary  :  Cybran Advanced Anti-Air System Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------------

local CAmphibiousStructureUnit = import('/lua/cybranunits.lua').CAmphibiousStructureUnit
local CAAMissileNaniteWeapon = import('/lua/cybranweapons.lua').CAAMissileNaniteWeapon

URB2304 = Class(CAmphibiousStructureUnit) {
    Weapons = {
        Missile01 = Class(CAAMissileNaniteWeapon) {},
    },
}

TypeClass = URB2304

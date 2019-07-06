---------------------------------------------------------------------------
-- File     :  /cdimage/units/URB2204/URB2204_script.lua
-- Author(s):  John Comes, David Tomandl
-- Summary  :  Cybran Anti-Air Flak Battery Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------------

local CAmphibiousStructureUnit = import('/lua/cybranunits.lua').CAmphibiousStructureUnit
local CAABurstCloudFlakArtilleryWeapon = import('/lua/cybranweapons.lua').CAABurstCloudFlakArtilleryWeapon

URB2204 = Class(CAmphibiousStructureUnit) {
    Weapons = {
        AAGun = Class(CAABurstCloudFlakArtilleryWeapon) {},
    },
}

TypeClass = URB2204

---------------------------------------------------------------------------
-- File     :  /cdimage/units/URB2104/URB2104_script.lua
-- Author(s):  John Comes, David Tomandl
-- Summary  :  Cybran Anti-Air Gun Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------------

local CAmphibiousStructureUnit = import('/lua/cybranunits.lua').CAmphibiousStructureUnit
local CAAAutocannon = import('/lua/cybranweapons.lua').CAAAutocannon

URB2104 = Class(CAmphibiousStructureUnit) {
    Weapons = {
        AAGun = Class(CAAAutocannon) {
            FxMuzzleScale = 2.25,
        },
    },
}

TypeClass = URB2104

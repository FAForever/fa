---------------------------------------------------------------------------
-- File     :  /cdimage/units/UEB2204/UEB2204_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix
-- Summary  :  UEF Flak Cannon Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------------

local TAmphibiousStructureUnit = import('/lua/terranunits.lua').TAmphibiousStructureUnit
local TAAFlakArtilleryCannon = import('/lua/terranweapons.lua').TAAFlakArtilleryCannon

UEB2204 = Class(TAmphibiousStructureUnit) {
    Weapons = {
        AAGun = Class(TAAFlakArtilleryCannon) {},

    },
}

TypeClass = UEB2204

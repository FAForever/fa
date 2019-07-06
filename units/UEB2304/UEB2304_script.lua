---------------------------------------------------------------------------
-- File     :  /cdimage/units/UEB2304/UEB2304_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix
-- Summary  :  UEF Advanced AA System Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------------

local TAmphibiousStructureUnit = import('/lua/terranunits.lua').TAmphibiousStructureUnit
local TSAMLauncher = import('/lua/terranweapons.lua').TSAMLauncher

UEB2304 = Class(TAmphibiousStructureUnit) {
    Weapons = {
        MissileRack01 = Class(TSAMLauncher) {},
    },
}

TypeClass = UEB2304

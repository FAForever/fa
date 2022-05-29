#****************************************************************************
#**
#**  File     :  /cdimage/units/UEB2204/UEB2204_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
#**
#**  Summary  :  UEF Flak Cannon Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local TStructureUnit = import('/lua/terranunits.lua').TStructureUnit
local TAAFlakArtilleryCannon = import('/lua/terranweapons.lua').TAAFlakArtilleryCannon

UEB2204 = Class(TStructureUnit) {
    Weapons = {
        AAGun = Class(TAAFlakArtilleryCannon) {},
           
    },
}

TypeClass = UEB2204
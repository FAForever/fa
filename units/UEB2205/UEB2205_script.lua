#****************************************************************************
#**
#**  File     :  /cdimage/units/UEB2205/UEB2205_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
#**
#**  Summary  :  UEF Heavy Torpedo Launcher Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local TStructureUnit = import('/lua/terranunits.lua').TStructureUnit
local TANTorpedoAngler = import('/lua/terranweapons.lua').TANTorpedoAngler

UEB2205 = Class(TStructureUnit) {

    UpsideDown = false,

    Weapons = {
         Torpedo = Class(TANTorpedoAngler) {
       },
    },

}

TypeClass = UEB2205
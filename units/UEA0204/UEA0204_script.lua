#****************************************************************************
#**
#**  File     :  /cdimage/units/UEA0204/UEA0204_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
#**
#**  Summary  :  UEF Torpedo Bomber Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local TAirUnit = import('/lua/terranunits.lua').TAirUnit
local TANTorpedoAngler = import('/lua/terranweapons.lua').TANTorpedoAngler


UEA0204 = Class(TAirUnit) {
    Weapons = {
        Torpedo = Class(TANTorpedoAngler) {
        },
    },
}

TypeClass = UEA0204
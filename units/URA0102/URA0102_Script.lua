#****************************************************************************
#**
#**  File     :  /cdimage/units/URA0102/URA0102_script.lua
#**  Author(s):  John Comes, David Tomandl
#**
#**  Summary  :  Cybran Unit Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
#
# Cybran Interceptor Script : URA0102
#
local CAirUnit = import('/lua/cybranunits.lua').CAirUnit
local CAAAutocannon = import('/lua/cybranweapons.lua').CAAAutocannon

URA0102 = Class(CAirUnit) {
    Weapons = {
        AutoCannon = Class(CAAAutocannon) {},
        AutoCannon2 = Class(CAAAutocannon) {},
    },
}

TypeClass = URA0102

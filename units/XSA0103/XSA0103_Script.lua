#****************************************************************************
#**
#**  File     :  /data/units/XSA0103/XSA0103_script.lua
#**  Author(s):  Jessica St. Croix
#**
#**  Summary  :  Seraphim Bomber Script
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local SAirUnit = import('/lua/seraphimunits.lua').SAirUnit
local SDFBombOtheWeapon = import('/lua/seraphimweapons.lua').SDFBombOtheWeapon

XSA0103 = Class(SAirUnit) {
    Weapons = {
        Bomb = Class(SDFBombOtheWeapon) {},
    },
}

TypeClass = XSA0103
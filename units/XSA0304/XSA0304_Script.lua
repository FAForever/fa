#****************************************************************************
#**
#**  File     :  /units/XSA0304/XSA0304_script.lua
#**  Author(s):  Drew Staltman, Greg Kohne, Gordon Duclos
#**
#**  Summary  :  Seraphim Strategic Bomber Script
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local SAirUnit = import('/lua/seraphimunits.lua').SAirUnit
local SIFBombZhanaseeWeapon = import('/lua/seraphimweapons.lua').SIFBombZhanaseeWeapon

XSA0304 = Class(SAirUnit) {
    Weapons = {
        Bomb = Class(SIFBombZhanaseeWeapon) {},
    },
}
TypeClass = XSA0304
#****************************************************************************
#**
#**  File     :  /cdimage/units/XSB2204/XSB2204_script.lua
#**  Author(s):  Drew Staltman, Jessica St. Croix, Gordon Duclos, Aaron Lundquist
#**
#**  Summary  :  Seraphim Sinnatha Anti-Air Defense
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local SStructureUnit = import('/lua/seraphimunits.lua').SStructureUnit
local SAAOlarisCannonWeapon = import('/lua/seraphimweapons.lua').SAAOlarisCannonWeapon

XSB2204 = Class(SStructureUnit) {
    Weapons = {
        AAFizz = Class(SAAOlarisCannonWeapon) {},
    },
}
TypeClass = XSB2204
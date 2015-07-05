#****************************************************************************
#**
#**  File     :  /cdimage/units/XSL0205/XSL0205_script.lua
#**  Author(s):  Aaron Lundquist
#**
#**  Summary  :  Seraphim Iashavoh Mobile Anit-Air Cannon
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

#changed from SLandUnit
local SHoverLandUnit = import('/lua/seraphimunits.lua').SHoverLandUnit
local SAAOlarisCannonWeapon = import('/lua/seraphimweapons.lua').SAAOlarisCannonWeapon

#changed from SLandUnit
XSL0205 = Class(SHoverLandUnit) {
    Weapons = {
        AAGun = Class(SAAOlarisCannonWeapon) {},
    },
}
TypeClass = XSL0205
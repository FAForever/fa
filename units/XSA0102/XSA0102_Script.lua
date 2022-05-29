#****************************************************************************
#**
#**  File     :  /data/units/XSA0102/XSA0102_script.lua
#**  Author(s):  Jessica St. Croix, Greg Kohne, Aaron Lundquist
#**
#**  Summary  :  Seraphim Interceptor Script
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local SAirUnit = import('/lua/seraphimunits.lua').SAirUnit
local SeraphimWeapons = import('/lua/seraphimweapons.lua')
local SAAShleoCannonWeapon = SeraphimWeapons.SAAShleoCannonWeapon

XSA0102 = Class(SAirUnit) {
    Weapons = {
        SonicPulseBattery = Class(SAAShleoCannonWeapon) {},
    },
}

TypeClass = XSA0102
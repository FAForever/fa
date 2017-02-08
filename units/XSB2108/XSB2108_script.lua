#****************************************************************************
#**
#**  File     :  /cdimage/units/UAB2108/UAB2108_script.lua
#**  Author(s):  Greg Kohne, Aaron Lundquist
#**
#**  Summary  :  Seraphim Tactical Missile Launcher Script
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local SStructureUnit = import('/lua/seraphimunits.lua').SStructureUnit
local SLaanseMissileWeapon = import('/lua/seraphimweapons.lua').SLaanseMissileWeapon

XSB2108 = Class(SStructureUnit) {
    Weapons = {
        CruiseMissile = Class(SLaanseMissileWeapon) {},
    },
}
TypeClass = XSB2108

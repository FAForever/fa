#****************************************************************************
#**
#**  File     :  /units/XSS0202/XSS0202_script.lua
#**  Author(s):  Drew Staltman, Gordon Duclos, Aaron Lundquist
#**
#**  Summary  :  Seraphim Cruiser Script
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local SeraphimWeapons = import('/lua/seraphimweapons.lua')
local SSeaUnit = import('/lua/seraphimunits.lua').SSeaUnit
local SLaanseMissileWeapon = SeraphimWeapons.SLaanseMissileWeapon
local SAAOlarisCannonWeapon = SeraphimWeapons.SAAOlarisCannonWeapon
local SAAShleoCannonWeapon = SeraphimWeapons.SAAShleoCannonWeapon
local SAMElectrumMissileDefense = SeraphimWeapons.SAMElectrumMissileDefense

XSS0202 = Class(SSeaUnit) {
    Weapons = {
        Missile = Class(SLaanseMissileWeapon) {},
		RightAAGun = Class(SAAShleoCannonWeapon) {},
		LeftAAGun = Class(SAAOlarisCannonWeapon) {},
        AntiMissile = Class(SAMElectrumMissileDefense) {},
    },

    BackWakeEffect = {},
}

TypeClass = XSS0202
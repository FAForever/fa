--****************************************************************************
--**
--**  File     :  /units/XSS0202/XSS0202_script.lua
--**  Author(s):  Drew Staltman, Gordon Duclos, Aaron Lundquist
--**
--**  Summary  :  Seraphim Cruiser Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SeraphimWeapons = import("/lua/seraphimweapons.lua")
local SSeaUnit = import("/lua/seraphimunits.lua").SSeaUnit
local SLaanseMissileWeapon = SeraphimWeapons.SLaanseMissileWeapon
local SAAOlarisCannonWeapon = SeraphimWeapons.SAAOlarisCannonWeapon
local SAAShleoCannonWeapon = SeraphimWeapons.SAAShleoCannonWeapon
local SAMElectrumMissileDefense = SeraphimWeapons.SAMElectrumMissileDefense

---@class XSS0202 : SSeaUnit
XSS0202 = ClassUnit(SSeaUnit) {
    Weapons = {
        Missile = ClassWeapon(SLaanseMissileWeapon) {},
		RightAAGun = ClassWeapon(SAAShleoCannonWeapon) {},
		LeftAAGun = ClassWeapon(SAAOlarisCannonWeapon) {},
        AntiMissile = ClassWeapon(SAMElectrumMissileDefense) {},
    },

    BackWakeEffect = {},
}

TypeClass = XSS0202
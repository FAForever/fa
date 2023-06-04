--****************************************************************************
--**
--**  File     :  /cdimage/units/UEL0303/UEL0303_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Siege Assault Bot Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TerranWeaponFile = import("/lua/terranweapons.lua")
local TWalkingLandUnit = import("/lua/terranunits.lua").TWalkingLandUnit
local TDFHeavyPlasmaCannonWeapon = TerranWeaponFile.TDFHeavyPlasmaCannonWeapon
local TSAMLauncher = TerranWeaponFile.TSAMLauncher

---@class UEL0303 : TWalkingLandUnit
UEL0303 = ClassUnit(TWalkingLandUnit) {

    Weapons = {
        HeavyPlasma01 = ClassWeapon(TDFHeavyPlasmaCannonWeapon) {
            DisabledFiringBones = { 'Torso' },
        },
    },
}

TypeClass = UEL0303
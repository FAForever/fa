--****************************************************************************
--**
--**  File     :  /cdimage/units/UEL0106/UEL0106_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Light Assault Bot Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local TWalkingLandUnit = import("/lua/terranunits.lua").TWalkingLandUnit
local Unit = import("/lua/sim/unit.lua").Unit
local TDFMachineGunWeapon = import("/lua/terranweapons.lua").TDFMachineGunWeapon


---@class UEL0106 : TWalkingLandUnit
UEL0106 = ClassUnit(TWalkingLandUnit) {
    Weapons = {
        ArmCannonTurret = ClassWeapon(TDFMachineGunWeapon) {
            DisabledFiringBones = { 'Torso' },
        },
    },
}
TypeClass = UEL0106


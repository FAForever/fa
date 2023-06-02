--****************************************************************************
--**
--**  File     :  /cdimage/units/UAS0202/UAS0202_script.lua
--**  Author(s):  David Tomandl
--**
--**  Summary  :  Aeon Cruiser Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local AeonWeapons = import("/lua/aeonweapons.lua")
local ASeaUnit = import("/lua/aeonunits.lua").ASeaUnit
local AAAZealotMissileWeapon = AeonWeapons.AAAZealotMissileWeapon
local ADFCannonQuantumWeapon = AeonWeapons.ADFCannonQuantumWeapon
local AAMWillOWisp = AeonWeapons.AAMWillOWisp

---@class UAS0202 : ASeaUnit
UAS0202 = ClassUnit(ASeaUnit) {
    Weapons = {
        FrontTurret = ClassWeapon(ADFCannonQuantumWeapon) {},
        AntiAirMissiles01 = ClassWeapon(AAAZealotMissileWeapon) {},
        AntiAirMissiles02 = ClassWeapon(AAAZealotMissileWeapon) {},
        AntiMissile = ClassWeapon(AAMWillOWisp) {},
    },

    BackWakeEffect = {},
}

TypeClass = UAS0202
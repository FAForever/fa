--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB2101/UEB2101_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Terran Light Gun Tower Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TStructureUnit = import("/lua/terranunits.lua").TStructureUnit
local TDFLightPlasmaCannonWeapon = import("/lua/terranweapons.lua").TDFLightPlasmaCannonWeapon

---@class UEB2101 : TStructureUnit
UEB2101 = ClassUnit(TStructureUnit) {
    Weapons = {
        MainGun = ClassWeapon(TDFLightPlasmaCannonWeapon) {}
    },
}

TypeClass = UEB2101
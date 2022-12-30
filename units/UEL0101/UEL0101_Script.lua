--****************************************************************************
--**
--**  File     :  /cdimage/units/UEL0101/UEL0101_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Land Scout Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TConstructionUnit = import("/lua/terranunits.lua").TConstructionUnit
local TDFMachineGunWeapon = import("/lua/terranweapons.lua").TDFMachineGunWeapon

---@class UEL0101 : TConstructionUnit
UEL0101 = ClassUnit(TConstructionUnit) {
    
    Weapons = {
        MainGun = ClassWeapon(TDFMachineGunWeapon) {},
    },

}

TypeClass = UEL0101

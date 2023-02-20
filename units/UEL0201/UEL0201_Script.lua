--****************************************************************************
--**
--**  File     :  /cdimage/units/UEL0201/UEL0201_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Medium Tank Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TLandUnit = import("/lua/terranunits.lua").TLandUnit
local TDFGaussCannonWeapon = import("/lua/terranweapons.lua").TDFGaussCannonWeapon

---@class UEL0201 : TLandUnit
UEL0201 = ClassUnit(TLandUnit) {
    Weapons = {
        MainGun = ClassWeapon(TDFGaussCannonWeapon) {}
    },
}

TypeClass = UEL0201
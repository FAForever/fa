--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB2301/UEB2301_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Heavy Gun Tower Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TStructureUnit = import("/lua/terranunits.lua").TStructureUnit
local TDFGaussCannonWeapon = import("/lua/terranweapons.lua").TDFGaussCannonWeapon

---@class UEB2301 : TStructureUnit
UEB2301 = ClassUnit(TStructureUnit) {
    Weapons = {
        Gauss01 = ClassWeapon(TDFGaussCannonWeapon) {},
    },
}

TypeClass = UEB2301
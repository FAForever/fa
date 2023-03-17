--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB2304/UEB2304_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Advanced AA System Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TStructureUnit = import("/lua/terranunits.lua").TStructureUnit
local TSAMLauncher = import("/lua/terranweapons.lua").TSAMLauncher

---@class UEB2304 : TStructureUnit
UEB2304 = ClassUnit(TStructureUnit) {
    Weapons = {
        MissileRack01 = ClassWeapon(TSAMLauncher) {},
    },
}

TypeClass = UEB2304
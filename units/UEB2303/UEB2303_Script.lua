--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB2303/UEB2303_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Light Artillery Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TStructureUnit = import("/lua/terranunits.lua").TStructureUnit
local TIFArtilleryWeapon = import("/lua/terranweapons.lua").TIFArtilleryWeapon

---@class UEB2303 : TStructureUnit
UEB2303 = ClassUnit(TStructureUnit) {
    Weapons = {
        MainGun = ClassWeapon(TIFArtilleryWeapon) {},
    },
}

TypeClass = UEB2303
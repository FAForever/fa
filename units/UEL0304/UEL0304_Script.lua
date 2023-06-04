--****************************************************************************
--**
--**  File     :  /cdimage/units/UEL0304/UEL0304_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Mobile Heavy Artillery Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TLandUnit = import("/lua/terranunits.lua").TLandUnit
local TIFArtilleryWeapon = import("/lua/terranweapons.lua").TIFArtilleryWeapon

---@class UEL0304 : TLandUnit
UEL0304 = ClassUnit(TLandUnit) {
    Weapons = {
        MainGun = ClassWeapon(TIFArtilleryWeapon) {}
    },
}

TypeClass = UEL0304
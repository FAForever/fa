--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB2302/UEB2302_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Long Range Artillery Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TStructureUnit = import("/lua/terranunits.lua").TStructureUnit
local TIFArtilleryWeapon = import("/lua/terranweapons.lua").TIFArtilleryWeapon

---@class UEB2302 : TStructureUnit
UEB2302 = ClassUnit(TStructureUnit) {
    Weapons = {
        MainGun = ClassWeapon(TIFArtilleryWeapon) {
            FxMuzzleFlashScale = 3,
        }
    },
}

TypeClass = UEB2302
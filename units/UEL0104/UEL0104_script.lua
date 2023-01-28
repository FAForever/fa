--****************************************************************************
--**
--**  File     :  /cdimage/units/UEL0104/UEL0104_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Mobile Anti-Air Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local TLandUnit = import("/lua/terranunits.lua").TLandUnit
local TAALinkedRailgun = import("/lua/terranweapons.lua").TAALinkedRailgun

---@class UEL0104 : TLandUnit
UEL0104 = ClassUnit(TLandUnit) {
    Weapons = {
        AAGun = ClassWeapon(TAALinkedRailgun) {
            FxMuzzleFlashScale = 0.25,
        },
    },

}

TypeClass = UEL0104
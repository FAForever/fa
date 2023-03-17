----****************************************************************************
----**
----**  File     :  /cdimage/units/UEL0103/UEL0103_script.lua
----**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
----**
----**  Summary  :  Mobile Light Artillery Script
----**
----**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
----****************************************************************************
local TLandUnit = import("/lua/terranunits.lua").TLandUnit
local TIFHighBallisticMortarWeapon = import("/lua/terranweapons.lua").TIFHighBallisticMortarWeapon

---@class UEL0103 : TLandUnit
UEL0103 = ClassUnit(TLandUnit) {
    Weapons = {
        MainGun = ClassWeapon(TIFHighBallisticMortarWeapon) {}
    },
}

TypeClass = UEL0103

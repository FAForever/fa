--****************************************************************************
--**
--**  File     :  /units/XSA0303/XSA0303_script.lua
--**  Author(s):  Greg Kohne
--**
--**  Summary  :  Seraphim Air Superiority Fighter Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SAirUnit = import("/lua/seraphimunits.lua").SAirUnit
local SAALosaareAutoCannonWeapon = import("/lua/seraphimweapons.lua").SAALosaareAutoCannonWeaponAirUnit

---@class XSA0303 : SAirUnit
XSA0303 = ClassUnit(SAirUnit) {
    Weapons = {
        AutoCannon1 = ClassWeapon(SAALosaareAutoCannonWeapon) {},
    },
}

TypeClass = XSA0303
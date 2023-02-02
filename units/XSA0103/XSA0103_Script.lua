--****************************************************************************
--**
--**  File     :  /data/units/XSA0103/XSA0103_script.lua
--**  Author(s):  Jessica St. Croix
--**
--**  Summary  :  Seraphim Bomber Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SAirUnit = import("/lua/seraphimunits.lua").SAirUnit
local SDFBombOtheWeapon = import("/lua/seraphimweapons.lua").SDFBombOtheWeapon

---@class XSA0103 : SAirUnit
XSA0103 = ClassUnit(SAirUnit) {
    Weapons = {
        Bomb = ClassWeapon(SDFBombOtheWeapon) {},
    },
}

TypeClass = XSA0103
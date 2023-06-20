--****************************************************************************
--**
--**  File     :  /main/data/Units/XSA0204/XSA0204_script.lua
--**  Author(s):  Greg Kohne, Gordon Duclos
--**
--**  Summary  :  Seraphim Torpedo Bomber Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SAirUnit = import("/lua/seraphimunits.lua").SAirUnit
local SeraphimWeapons = import("/lua/seraphimweapons.lua")
local SANHeavyCavitationTorpedo = SeraphimWeapons.SANHeavyCavitationTorpedo

---@class XSA0204 : SAirUnit
XSA0204 = ClassUnit(SAirUnit) {
    Weapons = {
        Bomb = ClassWeapon(SANHeavyCavitationTorpedo) {},
    },
}
TypeClass = XSA0204
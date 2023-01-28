--****************************************************************************
--**
--**  File     :  /cdimage/units/XAL0104/XAL0104_script.lua
--**  Author(s):  Jessica St. Croix, Gordon Duclos
--**
--**  Summary  :  Seraphim Mobile Anti-Air Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local SWalkingLandUnit = import("/lua/seraphimunits.lua").SWalkingLandUnit
local SAAShleoCannonWeapon = import("/lua/seraphimweapons.lua").SAAShleoCannonWeapon

---@class XSL0104 : SWalkingLandUnit
XSL0104 = ClassUnit(SWalkingLandUnit) {
    Weapons = {
        AAGun = ClassWeapon(SAAShleoCannonWeapon) {},
    },
}
TypeClass = XSL0104
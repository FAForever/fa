--****************************************************************************
--**
--**  File     :  /cdimage/units/XSB2204/XSB2204_script.lua
--**  Author(s):  Drew Staltman, Jessica St. Croix, Gordon Duclos, Aaron Lundquist
--**
--**  Summary  :  Seraphim Sinnatha Anti-Air Defense
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SStructureUnit = import("/lua/seraphimunits.lua").SStructureUnit
local SAAOlarisCannonWeapon = import("/lua/seraphimweapons.lua").SAAOlarisCannonWeapon

---@class XSB2204 : SStructureUnit
XSB2204 = ClassUnit(SStructureUnit) {
    Weapons = {
        AAFizz = ClassWeapon(SAAOlarisCannonWeapon) {},
    },
}
TypeClass = XSB2204
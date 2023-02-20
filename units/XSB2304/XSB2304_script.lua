--****************************************************************************
--**
--**  File     :  /cdimage/units/UAB2304/UAB2304_script.lua
--**  Author(s):  John Comes, David Tomandl, Greg Kohne
--**
--**  Summary  :  Seraphim Advanced Anti-Air System Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SStructureUnit = import("/lua/seraphimunits.lua").SStructureUnit
local SAALosaareAutoCannonWeapon = import("/lua/seraphimweapons.lua").SAALosaareAutoCannonWeapon

---@class XSB2304 : SStructureUnit
XSB2304 = ClassUnit(SStructureUnit) {
    Weapons = {
        AntiAirMissiles = ClassWeapon(SAALosaareAutoCannonWeapon) {},
    },
}

TypeClass = XSB2304
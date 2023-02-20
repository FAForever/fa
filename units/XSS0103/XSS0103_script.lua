--****************************************************************************
--**
--**  File     :  /cdimage/units/XSS0103/XSS0103_script.lua
--**
--**  Summary  :  Seraphim Frigate Script: XSS0103
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SSeaUnit = import("/lua/seraphimunits.lua").SSeaUnit
local SWeapon = import("/lua/seraphimweapons.lua")

---@class XSS0103 : SSeaUnit
XSS0103 = ClassUnit(SSeaUnit) {
    Weapons = {
        MainGun = ClassWeapon(SWeapon.SDFShriekerCannon){},
        AntiAir = ClassWeapon(SWeapon.SAAShleoCannonWeapon){},
    },
}
TypeClass = XSS0103

-- File     :  /cdimage/units/XSL0111/XSL0111_script.lua
-- Author(s):  Drew Staltman, Gordon Duclos
-- Summary  :  Seraphim Mobile Missile Launcher Script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local SLandUnit = import("/lua/seraphimunits.lua").SLandUnit
local SLaanseMissileWeapon = import("/lua/seraphimweapons.lua").SLaanseMissileWeapon

---@class XSL0111 : SLandUnit
XSL0111 = ClassUnit(SLandUnit) {
    Weapons = {
        MissileRack = ClassWeapon(SLaanseMissileWeapon) { },
    },
}
TypeClass = XSL0111

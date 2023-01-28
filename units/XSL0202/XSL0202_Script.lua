--****************************************************************************
--**
--**  File     :  /units/XSL0202/XSL0202_script.lua
--**
--**  Summary  :  Seraphim Heavy Bot Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local SWalkingLandUnit = import("/lua/seraphimunits.lua").SWalkingLandUnit
local SDFAireauBolterWeapon = import("/lua/seraphimweapons.lua").SDFAireauBolterWeapon02

---@class XSL0202 : SWalkingLandUnit
XSL0202 = ClassUnit(SWalkingLandUnit) {
    Weapons = {
        MainGun = ClassWeapon(SDFAireauBolterWeapon) {}
    },
}
TypeClass = XSL0202
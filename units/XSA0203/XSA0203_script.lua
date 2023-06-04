--****************************************************************************
--**
--**  File     :  /cdimage/units/UAA0203/UAA0203_script.lua
--**  Author(s):  Drew Staltman, Gordon Duclos
--**
--**  Summary  :  Seraphim Gunship Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SAirUnit = import("/lua/seraphimunits.lua").SAirUnit
local SDFPhasicAutoGunWeapon = import("/lua/seraphimweapons.lua").SDFPhasicAutoGunWeapon

---@class XSA0203 : SAirUnit
XSA0203 = ClassUnit(SAirUnit) {
    Weapons = {
        TurretLeft = ClassWeapon(SDFPhasicAutoGunWeapon) {},
        TurretRight = ClassWeapon(SDFPhasicAutoGunWeapon) {},
    },
}
TypeClass = XSA0203
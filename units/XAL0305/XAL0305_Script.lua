--****************************************************************************
--**
--**  File     :  /data/units/XAL0305/XAL0305_script.lua
--**  Author(s):  Jessica St. Croix
--**
--**  Summary  :  Aeon Sniper Bot Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local AWalkingLandUnit = import("/lua/aeonunits.lua").AWalkingLandUnit
local ADFHeavyDisruptorCannonWeapon = import("/lua/aeonweapons.lua").ADFHeavyDisruptorCannonWeapon

---@class XAL0305 : AWalkingLandUnit
XAL0305 = ClassUnit(AWalkingLandUnit) {
    Weapons = {
        MainGun = ClassWeapon(ADFHeavyDisruptorCannonWeapon) {}
    },
}

TypeClass = XAL0305
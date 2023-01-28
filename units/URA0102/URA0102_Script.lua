--****************************************************************************
--**
--**  File     :  /cdimage/units/URA0102/URA0102_script.lua
--**  Author(s):  John Comes, David Tomandl
--**
--**  Summary  :  Cybran Unit Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
--
-- Cybran Interceptor Script : URA0102
--
local CAirUnit = import("/lua/cybranunits.lua").CAirUnit
local CAAAutocannon = import("/lua/cybranweapons.lua").CAAAutocannon

---@class URA0102 : CAirUnit
URA0102 = ClassUnit(CAirUnit) {
    Weapons = {
        AutoCannon = ClassWeapon(CAAAutocannon) {},
        AutoCannon2 = ClassWeapon(CAAAutocannon) {},
    },
}

TypeClass = URA0102

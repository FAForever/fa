--****************************************************************************
--**
--**  File     :  /cdimage/units/UEA0303/UEA0303_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Supersonic Fighter Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TAirUnit = import("/lua/terranunits.lua").TAirUnit
local TAAGinsuRapidPulseWeapon = import("/lua/terranweapons.lua").TAAGinsuRapidPulseWeapon

---@class UEA0303 : TAirUnit
UEA0303 = ClassUnit(TAirUnit) {
    Weapons = {
        RightBeam = ClassWeapon(TAAGinsuRapidPulseWeapon) {},
        LeftBeam = ClassWeapon(TAAGinsuRapidPulseWeapon) {},
    },
}

TypeClass = UEA0303
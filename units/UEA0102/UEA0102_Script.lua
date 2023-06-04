--****************************************************************************
--**
--**  File     :  /cdimage/units/UEA0102/UEA0102_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Terran Interceptor Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TAirUnit = import("/lua/terranunits.lua").TAirUnit
local TAirToAirLinkedRailgun = import("/lua/terranweapons.lua").TAirToAirLinkedRailgun

---@class UEA0102 : TAirUnit
UEA0102 = ClassUnit(TAirUnit) {
    PlayDestructionEffects = true,

    Weapons = {
        LinkedRailGun = ClassWeapon(TAirToAirLinkedRailgun) {},
    },
}

TypeClass = UEA0102
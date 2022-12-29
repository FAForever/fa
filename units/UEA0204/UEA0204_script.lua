--****************************************************************************
--**
--**  File     :  /cdimage/units/UEA0204/UEA0204_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Torpedo Bomber Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TAirUnit = import("/lua/terranunits.lua").TAirUnit
local TANTorpedoAngler = import("/lua/terranweapons.lua").TANTorpedoAngler


---@class UEA0204 : TAirUnit
UEA0204 = ClassUnit(TAirUnit) {
    Weapons = {
        Torpedo = ClassWeapon(TANTorpedoAngler) {
        },
    },
}

TypeClass = UEA0204
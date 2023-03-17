--****************************************************************************
--**
--**  File     :  /cdimage/units/URA0204/URA0204_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix, Gordon Duclos
--**
--**  Summary  :  Cybran Torpedo Bomber Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CAirUnit = import("/lua/cybranunits.lua").CAirUnit
local CIFNaniteTorpedoWeapon = import("/lua/cybranweapons.lua").CIFNaniteTorpedoWeapon


---@class URA0204 : CAirUnit
URA0204 = ClassUnit(CAirUnit) {
    Weapons = {
        Bomb = ClassWeapon(CIFNaniteTorpedoWeapon) {},
    },
}

TypeClass = URA0204
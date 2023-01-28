--****************************************************************************
--**
--**  File     :  /cdimage/units/URL0111/URL0111_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Cybran Mobile Missile Launcher Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CLandUnit = import("/lua/cybranunits.lua").CLandUnit
local CIFMissileLoaWeapon = import("/lua/cybranweapons.lua").CIFMissileLoaWeapon

---@class URL0111 : CLandUnit
URL0111 = ClassUnit(CLandUnit) {
    Weapons = {
        MissileRack = ClassWeapon(CIFMissileLoaWeapon) {},
    },
}

TypeClass = URL0111

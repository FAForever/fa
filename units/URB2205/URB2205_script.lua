--****************************************************************************
--**
--**  File     :  /cdimage/units/URB2205/URB2205_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Cybran Heavy Torpedo Launcher Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CStructureUnit = import("/lua/cybranunits.lua").CStructureUnit
local CANNaniteTorpedoWeapon = import("/lua/cybranweapons.lua").CANNaniteTorpedoWeapon

---@class URB2205 : CStructureUnit
URB2205 = ClassUnit(CStructureUnit) {
    Weapons = {
        Turret01 = ClassWeapon(CANNaniteTorpedoWeapon) {},
    },
}

TypeClass = URB2205
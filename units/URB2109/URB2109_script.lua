--****************************************************************************
--**
--**  File     :  /cdimage/units/URB2109/URB2109_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Cybran Ground-based Torpedo Launcher Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CStructureUnit = import("/lua/cybranunits.lua").CStructureUnit
local CANNaniteTorpedoWeapon = import("/lua/cybranweapons.lua").CANNaniteTorpedoWeapon


---@class URB2109 : CStructureUnit
URB2109 = ClassUnit(CStructureUnit) {
    Weapons = {
        Turret01 = ClassWeapon(CANNaniteTorpedoWeapon) {},
    },
}

TypeClass = URB2109
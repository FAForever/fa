--****************************************************************************
--**
--**  File     :  /cdimage/units/UAA0303/UAA0303_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Aeon Air Superiority Fighter Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local AAirUnit = import("/lua/aeonunits.lua").AAirUnit
local AAAAutocannonQuantumWeapon = import("/lua/aeonweapons.lua").AAAAutocannonQuantumWeapon

---@class UAA0303 : AAirUnit
UAA0303 = ClassUnit(AAirUnit) {
    Weapons = {
        AutoCannon1 = ClassWeapon(AAAAutocannonQuantumWeapon) {},
    },
}

TypeClass = UAA0303
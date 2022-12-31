--****************************************************************************
--**
--**  File     :  /cdimage/units/UAB2304/UAB2304_script.lua
--**  Author(s):  John Comes, David Tomandl
--**
--**  Summary  :  Aeon Advanced Anti-Air System Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local AStructureUnit = import("/lua/aeonunits.lua").AStructureUnit
local AAAZealotMissileWeapon = import("/lua/aeonweapons.lua").AAAZealotMissileWeapon

---@class UAB2304 : AStructureUnit
UAB2304 = ClassUnit(AStructureUnit) {
    Weapons = {
        AntiAirMissiles = ClassWeapon(AAAZealotMissileWeapon) {},
    },
}

TypeClass = UAB2304
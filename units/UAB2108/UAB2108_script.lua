-----------------------------------------------------------------
-- File     :  /cdimage/units/UAB2108/UAB2108_script.lua
-- Author(s):  John Comes, David Tomandl
-- Summary  :  Aeon Tactical Missile Launcher Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local ACruiseMissileWeapon = import("/lua/aeonweapons.lua").ACruiseMissileWeapon
local AStructureUnit = import("/lua/aeonunits.lua").AStructureUnit

---@class UAB2108 : AStructureUnit
UAB2108 = ClassUnit(AStructureUnit) {
    Weapons = {
        CruiseMissile = ClassWeapon(ACruiseMissileWeapon) {},
    },
}

TypeClass = UAB2108

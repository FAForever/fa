--****************************************************************************
--**
--**  File     :  /cdimage/units/UAB4302/UAB4302_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Aeon Strategic Missile Defense Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local AStructureUnit = import("/lua/aeonunits.lua").AStructureUnit
local AAMSaintWeapon = import("/lua/aeonweapons.lua").AAMSaintWeapon

---@class UAB4302 : AStructureUnit
UAB4302 = ClassUnit(AStructureUnit) {

    Weapons = {
        MissileRack = ClassWeapon(AAMSaintWeapon) { },
    },
}

TypeClass = UAB4302
--****************************************************************************
--**
--**  File     :  /cdimage/units/UAB2301/UAB2301_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Aeon Heavy Gun Tower Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local AStructureUnit = import("/lua/aeonunits.lua").AStructureUnit

---@class UAB2301 : AStructureUnit
UAB2301 = ClassUnit(AStructureUnit) {
    Weapons = {
        MainGun = ClassWeapon(import("/lua/aeonweapons.lua").ADFCannonOblivionWeapon03) {}
    },
}

TypeClass = UAB2301
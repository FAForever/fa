--****************************************************************************
--**
--**  File     :  /cdimage/units/UAB2101/UAB2101_script.lua
--**  Author(s):  John Comes, David Tomandl
--**
--**  Summary  :  Aeon Light Laser Tower Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local AStructureUnit = import("/lua/aeonunits.lua").AStructureUnit
local ADFGravitonProjectorWeapon = import("/lua/aeonweapons.lua").ADFGravitonProjectorWeapon

---@class UAB2101 : AStructureUnit
UAB2101 = ClassUnit(AStructureUnit) {
    Weapons = {
        MainGun = ClassWeapon(ADFGravitonProjectorWeapon) {},
    },
}

TypeClass = UAB2101
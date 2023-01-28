--****************************************************************************
--**
--**  File     :  /cdimage/units/URB2101/URB2101_script.lua
--**  Author(s):  John Comes, David Tomandl
--**
--**  Summary  :  Cybran Light Gun Tower Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CStructureUnit = import("/lua/cybranunits.lua").CStructureUnit
local CDFLaserHeavyWeapon = import("/lua/cybranweapons.lua").CDFLaserHeavyWeapon


---@class URB2101 : CStructureUnit
URB2101 = ClassUnit(CStructureUnit) {

    Weapons = {
        MainGun = ClassWeapon(CDFLaserHeavyWeapon) {}
    },
}

TypeClass = URB2101

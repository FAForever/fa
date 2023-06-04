--****************************************************************************
--**
--**  File     :  /cdimage/units/UAL0104/UAL0104_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Aeon Mobile Anti-Air Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local AHoverLandUnit = import("/lua/aeonunits.lua").AHoverLandUnit
local AAASonicPulseBatteryWeapon = import("/lua/aeonweapons.lua").AAASonicPulseBatteryWeapon


---@class UAL0104 : AHoverLandUnit
UAL0104 = ClassUnit(AHoverLandUnit) {

    Weapons = {
        AAGun = ClassWeapon(AAASonicPulseBatteryWeapon) {},
    },
}


TypeClass = UAL0104
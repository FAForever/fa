#****************************************************************************
#**
#**  File     :  /cdimage/units/UAB2104/UAB2104_script.lua
#**  Author(s):  John Comes, David Tomandl
#**
#**  Summary  :  Aeon Anti-Air Gun Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local AStructureUnit = import('/lua/aeonunits.lua').AStructureUnit
local AAASonicPulseBatteryWeapon = import('/lua/aeonweapons.lua').AAASonicPulseBatteryWeapon

UAB2104 = Class(AStructureUnit) {

    Weapons = {
        AAGun = Class(AAASonicPulseBatteryWeapon) {
            FxMuzzleScale = 2.25,
        },
    },
}

TypeClass = UAB2104

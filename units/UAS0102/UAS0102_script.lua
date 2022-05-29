#****************************************************************************
#**
#**  File     :  /cdimage/units/UAS0102/UAS0102_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
#**
#**  Summary  :  Aeon Attack Boat Script: UAS0102
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local ASeaUnit = import('/lua/aeonunits.lua').ASeaUnit
local AAASonicPulseBatteryWeapon = import('/lua/aeonweapons.lua').AAASonicPulseBatteryWeapon

UAS0102 = Class(ASeaUnit) {

    Weapons = {
        MainGun = Class(AAASonicPulseBatteryWeapon) {},
    },
    
}

TypeClass = UAS0102
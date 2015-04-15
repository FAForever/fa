#****************************************************************************
#**
#**  File     :  /cdimage/units/URL0202/URL0202_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
#**
#**  Summary  :  Cybran Heavy Tank Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local CLandUnit = import('/lua/cybranunits.lua').CLandUnit
local CDFLaserHeavyWeapon = import('/lua/cybranweapons.lua').CDFLaserHeavyWeapon

URL0202 = Class(CLandUnit) {
    Weapons = {
        MainGun = Class(CDFLaserHeavyWeapon) {},
    },
}

TypeClass = URL0202
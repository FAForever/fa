#****************************************************************************
#**
#**  File     :  /cdimage/units/DRL0204/DRL0204_script.lua
#**  Author(s):  Dru Staltman, Eric Williamson, Gordon Duclos
#**
#**  Summary  :  Cybran Rocket Bot Script
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
DRL0204 = Class(import('/lua/cybranunits.lua').CWalkingLandUnit) {
    Weapons = {
        RocketBackpack = Class(import('/lua/cybranweapons.lua').CDFRocketIridiumWeapon02) {},
    },
}
TypeClass = DRL0204

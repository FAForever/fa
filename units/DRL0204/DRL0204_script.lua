--****************************************************************************
--**
--**  File     :  /cdimage/units/DRL0204/DRL0204_script.lua
--**  Author(s):  Dru Staltman, Eric Williamson, Gordon Duclos
--**
--**  Summary  :  Cybran Rocket Bot Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

---@class DRL0204 : CWalkingLandUnit
DRL0204 = ClassUnit(import("/lua/cybranunits.lua").CWalkingLandUnit) {
    Weapons = {
        RocketBackpack = ClassWeapon(import("/lua/cybranweapons.lua").CDFRocketIridiumWeapon02) {},
    },
}
TypeClass = DRL0204
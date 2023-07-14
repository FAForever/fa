-- File     :  /cdimage/units/DRL0204/DRL0204_script.lua
-- Author(s):  Dru Staltman, Eric Williamson, Gordon Duclos
-- Summary  :  Cybran Rocket Bot Script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------
local CDFRocket = import("/lua/cybranweapons.lua").CDFRocketIridiumWeapon02

---@class DRL0204 : CWalkingLandUnit
DRL0204 = ClassUnit(import("/lua/cybranunits.lua").CWalkingLandUnit) {
    Weapons = {
        RocketBackpack = ClassWeapon(CDFRocket) {},
    },
}
TypeClass = DRL0204
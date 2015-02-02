#****************************************************************************
#**
#**  File     :  /data/units/XAA0306/XAA0306_script.lua
#**  Author(s):  Jessica St. Croix, Matt Vainio
#**
#**  Summary  :  Aeon Torpedo Cluster Bomber Script
#**
#**  Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local AAirUnit = import('/lua/aeonunits.lua').AAirUnit
local AANDepthChargeBombWeapon = import('/lua/aeonweapons.lua').AANDepthChargeBombWeapon


XAA0306 = Class(AAirUnit) {
    Weapons = {
        Bomb = Class(AANDepthChargeBombWeapon) {},
    },
}

TypeClass = XAA0306
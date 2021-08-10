#****************************************************************************
#**
#**  File     :  /data/units/XAA0202/XAA0202_script.lua
#**  Author(s):  Jessica St. Croix
#**
#**  Summary  :  Aeon Combat Fighter Script
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local AAirUnit = import('/lua/aeonunits.lua').AAirUnit
local AAAAutocannonQuantumWeapon = import('/lua/aeonweapons.lua').AAALightDisplacementAutocannonMissileWeapon

XAA0202 = Class(AAirUnit) {
    Weapons = {
        AutoCannon1 = AAAAutocannonQuantumWeapon,
    },
}

TypeClass = XAA0202
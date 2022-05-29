#****************************************************************************
#**
#**  File     :  /data/units/XAA0305/XAA0305_script.lua
#**  Author(s):  Jessica St. Croix
#**
#**  Summary  :  Aeon AA Gunship Script
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local AAirUnit = import('/lua/aeonunits.lua').AAirUnit
local ADFQuadLaserLightWeapon = import('/lua/aeonweapons.lua').ADFQuadLaserLightWeapon
local AAAZealot02MissileWeapon = import('/lua/aeonweapons.lua').AAAZealot02MissileWeapon

XAA0305 = Class(AAirUnit) {
    Weapons = {
        Turret = Class(ADFQuadLaserLightWeapon) {},
        AAGun01 = Class(AAAZealot02MissileWeapon) {},
        AAGun02 = Class(AAAZealot02MissileWeapon) {},
    },
}

TypeClass = XAA0305
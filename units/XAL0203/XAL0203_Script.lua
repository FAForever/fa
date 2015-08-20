-----------------------------------------------------------------
-- File     :  /data/units/XAL0203/XAL0203_script.lua
-- Author(s):  Jessica St. Croix
-- Summary  :  Aeon Assault Tank Script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local AHoverLandUnit = import('/lua/aeonunits.lua').AHoverLandUnit
local ADFQuantumAutogunWeapon = import('/lua/aeonweapons.lua').ADFQuantumAutogunWeapon
local SlowHover = import('/lua/defaultunits.lua').SlowHoverLandUnit

XAL0203 = Class(AHoverLandUnit, SlowHover) {
    Weapons = {
        MainGun = Class(ADFQuantumAutogunWeapon) {}
    },
}
TypeClass = XAL0203

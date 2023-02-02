--****************************************************************************
--**
--**  File     :  /cdimage/units/UEL0111/UEL0111_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Mobile Missile Launcher Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TLandUnit = import("/lua/terranunits.lua").TLandUnit
local TIFCruiseMissileUnpackingLauncher = import("/lua/terranweapons.lua").TIFCruiseMissileUnpackingLauncher

---@class UEL0111 : TLandUnit
UEL0111 = ClassUnit(TLandUnit) {
    Weapons = {
        MissileWeapon = ClassWeapon(TIFCruiseMissileUnpackingLauncher) 
        {
            FxMuzzleFlash = {'/effects/emitters/terran_mobile_missile_launch_01_emit.bp'},
        },
    },
}

TypeClass = UEL0111
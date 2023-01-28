--****************************************************************************
--**
--**  File     :  /cdimage/units/URB2301/URB2301_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Cybran Heavy Gun Tower Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CStructureUnit = import("/lua/cybranunits.lua").CStructureUnit
local CDFLaserHeavyWeapon = import("/lua/cybranweapons.lua").CDFLaserHeavyWeapon


---@class URB2301 : CStructureUnit
URB2301 = ClassUnit(CStructureUnit) {

    Weapons = {
        MainGun = ClassWeapon(CDFLaserHeavyWeapon) {
        FxMuzzleFlash = {'/effects/emitters/particle_cannon_muzzle_02_emit.bp'},
    }
    },
}

TypeClass = URB2301

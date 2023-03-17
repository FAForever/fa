--****************************************************************************
--**
--**  File     :  /cdimage/units/URL0202/URL0202_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Cybran Heavy Tank Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CLandUnit = import("/lua/cybranunits.lua").CLandUnit
local CDFLaserHeavyWeapon = import("/lua/cybranweapons.lua").CDFLaserHeavyWeapon

---@class URL0202 : CLandUnit
URL0202 = ClassUnit(CLandUnit) {
    Weapons = {
        MainGun = ClassWeapon(CDFLaserHeavyWeapon) {},
        FxMuzzleFlash = {'/effects/emitters/particle_cannon_muzzle_02_emit.bp'},
    },
}

TypeClass = URL0202

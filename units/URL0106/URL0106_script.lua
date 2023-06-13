--****************************************************************************
--**
--**  File     :  /cdimage/units/URL0106/URL0106_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Cybran Light Infantry Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CWalkingLandUnit = import("/lua/cybranunits.lua").CWalkingLandUnit
local CDFLaserPulseLightWeapon = import("/lua/cybranweapons.lua").CDFLaserPulseLightWeapon

---@class URL0106 : CWalkingLandUnit
URL0106 = ClassUnit(CWalkingLandUnit) {
    Weapons = {
        MainGun = ClassWeapon(CDFLaserPulseLightWeapon) {},
    },
}

TypeClass = URL0106
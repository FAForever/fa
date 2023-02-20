--****************************************************************************
--**
--**  File     :  /cdimage/units/UEL0202/UEL0202_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Heavy Tank Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local TLandUnit = import("/lua/terranunits.lua").TLandUnit
local TDFGaussCannonWeapon = import("/lua/terranweapons.lua").TDFGaussCannonWeapon

---@class UEL0202 : TLandUnit
UEL0202 = ClassUnit(TLandUnit) {
    Weapons = {
        FrontTurret01 = ClassWeapon(TDFGaussCannonWeapon) {}
    },
}

TypeClass = UEL0202
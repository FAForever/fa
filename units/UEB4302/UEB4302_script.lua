--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB4302/UEB4302_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Strategic Missile Defense Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TStructureUnit = import("/lua/terranunits.lua").TStructureUnit
local TAMInterceptorWeapon = import("/lua/terranweapons.lua").TAMInterceptorWeapon

---@class UEB4302 : TStructureUnit
UEB4302 = ClassUnit(TStructureUnit) {
    Weapons = {
        AntiNuke = ClassWeapon(TAMInterceptorWeapon) { },
    },
}

TypeClass = UEB4302
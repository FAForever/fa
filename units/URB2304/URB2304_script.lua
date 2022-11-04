--****************************************************************************
--**
--**  File     :  /cdimage/units/URB2304/URB2304_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Cybran Advanced Anti-Air System Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CStructureUnit = import("/lua/cybranunits.lua").CStructureUnit
local CAAMissileNaniteWeapon = import("/lua/cybranweapons.lua").CAAMissileNaniteWeapon

---@class URB2304 : CStructureUnit
URB2304 = Class(CStructureUnit) {
    Weapons = {
        Missile01 = Class(CAAMissileNaniteWeapon) {},
    },
}

TypeClass = URB2304
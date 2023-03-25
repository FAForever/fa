-- File     :  /cdimage/units/XSB4302/XSB4302_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix, Matt Vainio
-- Summary  :  Seraphim Strategic Missile Defense Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--------------------------------------------------------------------------
local SStructureUnit = import("/lua/seraphimunits.lua").SStructureUnit
local SIFHuAntiNukeWeapon = import("/lua/seraphimweapons.lua").SIFHuAntiNukeWeapon

---@class XSB4302 : SStructureUnit
XSB4302 = ClassUnit(SStructureUnit) {

    Weapons = {
        MissileRack = ClassWeapon(SIFHuAntiNukeWeapon) { },
    },
}

TypeClass = XSB4302
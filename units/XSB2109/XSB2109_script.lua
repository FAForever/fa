--****************************************************************************
--**
--**  File     :  /cdimage/units/XSB2109/XSB2109_script.lua
--**  Author(s):  Jessica St. Croix, Gordon Duclos, Aaron Lundquist
--**
--**  Summary  :  Seraphim Torpedo Launcher Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SStructureUnit = import("/lua/seraphimunits.lua").SStructureUnit
local SANUallCavitationTorpedo = import("/lua/seraphimweapons.lua").SANUallCavitationTorpedo

---@class XSB2109 : SStructureUnit
XSB2109 = ClassUnit(SStructureUnit) {
    Weapons = {
        Turret01 = ClassWeapon(SANUallCavitationTorpedo) {},
    },     
}
TypeClass = XSB2109
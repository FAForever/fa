--****************************************************************************
--**
--**  File     :  /cdimage/units/UAB2301/UAB2301_script.lua
--**  Author(s):  Greg Kohne
--**
--**  Summary  :  Aeon Heavy Gun Tower Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SStructureUnit = import("/lua/seraphimunits.lua").SStructureUnit
local SDFUltraChromaticBeamGenerator = import("/lua/seraphimweapons.lua").SDFUltraChromaticBeamGenerator

---@class XSB2301 : SStructureUnit
XSB2301 = ClassUnit(SStructureUnit) {
    Weapons = {
        MainGun = ClassWeapon(SDFUltraChromaticBeamGenerator) {}
    },
}

TypeClass = XSB2301
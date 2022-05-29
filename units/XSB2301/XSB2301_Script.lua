#****************************************************************************
#**
#**  File     :  /cdimage/units/UAB2301/UAB2301_script.lua
#**  Author(s):  Greg Kohne
#**
#**  Summary  :  Aeon Heavy Gun Tower Script
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local SStructureUnit = import('/lua/seraphimunits.lua').SStructureUnit
local SDFUltraChromaticBeamGenerator = import('/lua/seraphimweapons.lua').SDFUltraChromaticBeamGenerator

XSB2301 = Class(SStructureUnit) {
    Weapons = {
        MainGun = Class(SDFUltraChromaticBeamGenerator) {}
    },
}

TypeClass = XSB2301
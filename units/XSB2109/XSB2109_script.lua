#****************************************************************************
#**
#**  File     :  /cdimage/units/XSB2109/XSB2109_script.lua
#**  Author(s):  Jessica St. Croix, Gordon Duclos, Aaron Lundquist
#**
#**  Summary  :  Seraphim Torpedo Launcher Script
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local SStructureUnit = import('/lua/seraphimunits.lua').SStructureUnit
local SANUallCavitationTorpedo = import('/lua/seraphimweapons.lua').SANUallCavitationTorpedo

XSB2109 = Class(SStructureUnit) {
    Weapons = {
        Turret01 = Class(SANUallCavitationTorpedo) {},
    },     
}
TypeClass = XSB2109
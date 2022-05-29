#****************************************************************************
#**
#**  File     :  /data/units/XSL0201/XSL0201_script.lua
#**  Author(s):  Jessica St. Croix, Greg Kohne, Aaron Lundquist
#**
#**  Summary  :  Seraphim Medium Tank Script
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local SLandUnit = import('/lua/seraphimunits.lua').SLandUnit
local SDFOhCannon = import('/lua/seraphimweapons.lua').SDFOhCannon

XSL0201 = Class(SLandUnit) {
    Weapons = {
        MainGun = Class(SDFOhCannon) {}
    },
}
TypeClass = XSL0201

--****************************************************************************
--**
--**  File     :  /cdimage/units/XSL0304/XSL0304_script.lua
--**  Author(s):  John Comes, David Tomandl, Matt Vainio, Aaron Lundquist
--**
--**  Summary  :  Seraphim Mobile Heavy Artillery
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SWalkingLandUnit = import("/lua/seraphimunits.lua").SWalkingLandUnit
local SIFSuthanusArtilleryCannon = import("/lua/seraphimweapons.lua").SIFSuthanusMobileArtilleryCannon

---@class XSL0304 : SWalkingLandUnit
XSL0304 = ClassUnit(SWalkingLandUnit) {
    Weapons = {
        MainGun = ClassWeapon(SIFSuthanusArtilleryCannon) {}
    },
 
}

TypeClass = XSL0304
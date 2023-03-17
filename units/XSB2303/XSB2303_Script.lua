--****************************************************************************
--**
--**  File     :  /cdimage/units/UAB2303/UAB2303_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Aeon Light Artillery Installation Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SStructureUnit = import("/lua/seraphimunits.lua").SStructureUnit
local SIFZthuthaamArtilleryCannon = import("/lua/seraphimweapons.lua").SIFZthuthaamArtilleryCannon

---@class XSB2303 : SStructureUnit
XSB2303 = ClassUnit(SStructureUnit) {

    Weapons = {
        MainGun = ClassWeapon(SIFZthuthaamArtilleryCannon) {},
    },
}

TypeClass = XSB2303
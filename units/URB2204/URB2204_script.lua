--****************************************************************************
--**
--**  File     :  /cdimage/units/URB2204/URB2204_script.lua
--**  Author(s):  John Comes, David Tomandl
--**
--**  Summary  :  Cybran Anti-Air Flak Battery Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CStructureUnit = import("/lua/cybranunits.lua").CStructureUnit
local CAABurstCloudFlakArtilleryWeapon = import("/lua/cybranweapons.lua").CAABurstCloudFlakArtilleryWeapon

---@class URB2204 : CStructureUnit
URB2204 = ClassUnit(CStructureUnit) {
    Weapons = {
        AAGun = ClassWeapon(CAABurstCloudFlakArtilleryWeapon) {},
    },
}

TypeClass = URB2204
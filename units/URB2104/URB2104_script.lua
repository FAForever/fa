--****************************************************************************
--**
--**  File     :  /cdimage/units/URB2104/URB2104_script.lua
--**  Author(s):  John Comes, David Tomandl
--**
--**  Summary  :  Cybran Anti-Air Gun Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CStructureUnit = import("/lua/cybranunits.lua").CStructureUnit
local CAAAutocannon = import("/lua/cybranweapons.lua").CAAAutocannon


---@class URB2104 : CStructureUnit
URB2104 = ClassUnit(CStructureUnit) {

    Weapons = {
        AAGun = ClassWeapon(CAAAutocannon) {
            FxMuzzleScale = 2.25,
        },
    },
}


TypeClass = URB2104

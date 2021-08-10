#****************************************************************************
#**
#**  File     :  /cdimage/units/XSB2104/XSB2104_script.lua
#**
#**  Summary  :  Seraphim Anti-Air Gun Script
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local SStructureUnit = import('/lua/seraphimunits.lua').SStructureUnit
local SAAShleoCannonWeapon = import('/lua/seraphimweapons.lua').SAAShleoCannonWeapon

XSB2104 = Class(SStructureUnit) {

    Weapons = {
        AAGun = Class(SAAShleoCannonWeapon) {
            FxMuzzleScale = 2.25,
        },
    },
}

TypeClass = XSB2104

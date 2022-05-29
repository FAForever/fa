#****************************************************************************
#**
#**  File     :  /cdimage/units/UAL0304/UAL0304_script.lua
#**  Author(s):  John Comes, David Tomandl
#**
#**  Summary  :  Aeon Heavy Mobile Artillery Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local ALandUnit = import('/lua/aeonunits.lua').ALandUnit
local AIFArtillerySonanceShellWeapon = import('/lua/aeonweapons.lua').AIFArtillerySonanceShellWeapon

UAL0304 = Class(ALandUnit) {
    Weapons = {
        MainGun = Class(AIFArtillerySonanceShellWeapon) {
            FxMuzzleFlash = { 
                '/effects/emitters/aeon_heavy_artillery_flash_01_emit.bp', 
                '/effects/emitters/aeon_heavy_artillery_flash_02_emit.bp', 
            },
        },
    },

}

TypeClass = UAL0304
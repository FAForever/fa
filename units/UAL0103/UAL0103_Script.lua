--****************************************************************************
--**
--**  File     :  /cdimage/units/UAL0103/UAL0103_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Aeon Mobile Light Artillery Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local AHoverLandUnit = import("/lua/aeonunits.lua").AHoverLandUnit
local AIFMortarWeapon = import("/lua/aeonweapons.lua").AIFMortarWeapon

---@class UAL0103 : AHoverLandUnit
UAL0103 = ClassUnit(AHoverLandUnit) {
    Weapons = {
        MainGun = ClassWeapon(AIFMortarWeapon) {
            FxMuzzleFlash = {
                '/effects/emitters/aeon_mortar_flash_01_emit.bp',
                '/effects/emitters/aeon_mortar_flash_02_emit.bp',
            },
        }
    },
}

TypeClass = UAL0103
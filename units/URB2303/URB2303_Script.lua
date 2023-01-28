--****************************************************************************
--**
--**  File     :  /cdimage/units/URB2303/URB2303_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Cybran Light Artillery Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CStructureUnit = import("/lua/cybranunits.lua").CStructureUnit
local CIFArtilleryWeapon = import("/lua/cybranweapons.lua").CIFArtilleryWeapon

---@class URB2303 : CStructureUnit
URB2303 = ClassUnit(CStructureUnit) {
    Weapons = {
        MainGun = ClassWeapon(CIFArtilleryWeapon) {
            FxMuzzleFlash = {
                '/effects/emitters/cybran_artillery_muzzle_flash_01_emit.bp',
                '/effects/emitters/cybran_artillery_muzzle_flash_02_emit.bp',
                '/effects/emitters/cybran_artillery_muzzle_smoke_01_emit.bp',
            },
        }
    },
}

TypeClass = URB2303
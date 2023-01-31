--****************************************************************************
--**
--**  File     :  /cdimage/units/URL0304/URL0304_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Cybran Heavy Mobile Artillery Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CLandUnit = import("/lua/cybranunits.lua").CLandUnit
local CIFArtilleryWeapon = import("/lua/cybranweapons.lua").CIFArtilleryWeapon

---@class URL0304 : CLandUnit
URL0304 = ClassUnit(CLandUnit) {
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

TypeClass = URL0304
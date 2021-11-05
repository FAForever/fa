--****************************************************************************
--**
--**  File     :  /cdimage/units/URL0103/URL0103_script.lua
--**  Author(s):  John Comes, David Tomandl
--**
--**  Summary  :  Cybran Mobile Mortar Script
--**
--**  Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CWalkingLandUnit = import('/lua/cybranunits.lua').CWalkingLandUnit
local CIFGrenadeWeapon = import('/lua/cybranweapons.lua').CIFGrenadeWeapon

URL0103 = Class(CWalkingLandUnit) {

    Weapons = {
        MainGun = Class(CIFGrenadeWeapon) {
            FxMuzzleFlash = {
                '/effects/emitters/cybran_artillery_muzzle_flash_01_emit.bp',
                '/effects/emitters/cybran_artillery_muzzle_flash_02_emit.bp',
                '/effects/emitters/cannon_muzzle_smoke_02_emit.bp',
				'/effects/emitters/cybran_artillery_muzzle_shell_01_emit.bp',
				'/effects/emitters/cannon_muzzle_smoke_13_emit.bp',
            },
            FxMuzzleFlashScale = 0.5,
        },
    },
}

TypeClass = URL0103

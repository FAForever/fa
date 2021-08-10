#****************************************************************************
#**
#**  File     :  /cdimage/units/UES0203/UES0203_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
#**
#**  Summary  :  UEF Attack Sub Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local TSubUnit = import('/lua/terranunits.lua').TSubUnit
local TANTorpedoAngler = import('/lua/terranweapons.lua').TANTorpedoAngler
local TDFLightPlasmaCannonWeapon = import('/lua/terranweapons.lua').TDFLightPlasmaCannonWeapon

UES0203 = Class(TSubUnit) {
    PlayDestructionEffects = true,
    DeathThreadDestructionWaitTime = 0,

    Weapons = {
        Torpedo01 = Class(TANTorpedoAngler) {},
        PlasmaGun = Class(TDFLightPlasmaCannonWeapon) {}
    },
}


TypeClass = UES0203
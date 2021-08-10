--****************************************************************************
--**
--**  File     :  /data/units/xas0204/xas0204_script.lua
--**  Author(s):  Dru Staltman, Jessica St. Croix
--**
--**  Summary  :  Aeon Submarine Hunter Script
--**
--**  Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local ASubUnit = import('/lua/aeonunits.lua').ASubUnit
local AANChronoTorpedoWeapon = import('/lua/aeonweapons.lua').AANChronoTorpedoWeapon
local AIFQuasarAntiTorpedoWeapon = import('/lua/aeonweapons.lua').AIFQuasarAntiTorpedoWeapon

XAS0204 = Class(ASubUnit) {
    DeathThreadDestructionWaitTime = 0,
    Weapons = {
        Torpedo01 = Class(AANChronoTorpedoWeapon) {},
        Torpedo02 = Class(AANChronoTorpedoWeapon) {},
        AntiTorpedo01 = Class(AIFQuasarAntiTorpedoWeapon) {},
        AntiTorpedo02 = Class(AIFQuasarAntiTorpedoWeapon) {},
    },
}

TypeClass = XAS0204
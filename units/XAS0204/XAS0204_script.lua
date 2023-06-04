--****************************************************************************
--**
--**  File     :  /data/units/xas0204/xas0204_script.lua
--**  Author(s):  Dru Staltman, Jessica St. Croix
--**
--**  Summary  :  Aeon Submarine Hunter Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local ASubUnit = import("/lua/aeonunits.lua").ASubUnit
local AANChronoTorpedoWeapon = import("/lua/aeonweapons.lua").AANChronoTorpedoWeapon
local AIFQuasarAntiTorpedoWeapon = import("/lua/aeonweapons.lua").AIFQuasarAntiTorpedoWeapon

---@class XAS0204 : ASubUnit
XAS0204 = ClassUnit(ASubUnit) {
    DeathThreadDestructionWaitTime = 0,
    Weapons = {
        Torpedo01 = ClassWeapon(AANChronoTorpedoWeapon) {},
        Torpedo02 = ClassWeapon(AANChronoTorpedoWeapon) {},
        AntiTorpedo01 = ClassWeapon(AIFQuasarAntiTorpedoWeapon) {},
        AntiTorpedo02 = ClassWeapon(AIFQuasarAntiTorpedoWeapon) {},
    },
}

TypeClass = XAS0204
--****************************************************************************
--**
--**  File     :  /cdimage/units/uas0203/uas0203_script.lua
--**  Author(s):  John Comes, Jessica St. Croix
--**
--**  Summary  :  Aeon Attack Sub Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local ASubUnit = import("/lua/aeonunits.lua").ASubUnit
local AANChronoTorpedoWeapon = import("/lua/aeonweapons.lua").AANChronoTorpedoWeapon

---@class UAS0203 : ASubUnit
UAS0203 = ClassUnit(ASubUnit) {
    DeathThreadDestructionWaitTime = 0,
    Weapons = {
        Torpedo01 = ClassWeapon(AANChronoTorpedoWeapon) {},
    },
}

TypeClass = UAS0203
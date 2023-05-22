-----------------------------------------------------------------
-- File     :  /cdimage/units/UAS0304/UAS0304_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix
-- Summary  :  Aeon Strategic Missile Submarine Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local ASubUnit = import("/lua/aeonunits.lua").ASubUnit
local WeaponFile = import("/lua/aeonweapons.lua")
local AIFMissileTacticalSerpentineWeapon = WeaponFile.AIFMissileTacticalSerpentineWeapon
local AIFQuantumWarhead = WeaponFile.AIFQuantumWarhead

---@class UAS0304 : ASubUnit
UAS0304 = ClassUnit(ASubUnit) {
    DeathThreadDestructionWaitTime = 0,
    Weapons = {
        CruiseMissiles = ClassWeapon(AIFMissileTacticalSerpentineWeapon) {},
        NukeMissiles = ClassWeapon(AIFQuantumWarhead) {},
    },
}

TypeClass = UAS0304

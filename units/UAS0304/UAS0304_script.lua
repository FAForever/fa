-----------------------------------------------------------------
-- File     :  /cdimage/units/UAS0304/UAS0304_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix
-- Summary  :  Aeon Strategic Missile Submarine Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local ASubUnit = import('/lua/aeonunits.lua').ASubUnit
local WeaponFile = import('/lua/aeonweapons.lua')
local AIFMissileTacticalSerpentineWeapon = WeaponFile.AIFMissileTacticalSerpentineWeapon
local AIFQuantumWarhead = WeaponFile.AIFQuantumWarhead

UAS0304 = Class(ASubUnit)({
    DeathThreadDestructionWaitTime = 0,
    Weapons = {
        CruiseMissiles = Class(AIFMissileTacticalSerpentineWeapon)({}),
        NukeMissiles = Class(AIFQuantumWarhead)({}),
    },
})

TypeClass = UAS0304

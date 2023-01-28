-----------------------------------------------------------------
-- File     :  /cdimage/units/UEB2108/UEB2108_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix
-- Summary  :  UEF Tactical Cruise Missile Launcher Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local TStructureUnit = import("/lua/terranunits.lua").TStructureUnit
local TIFCruiseMissileLauncher = import("/lua/terranweapons.lua").TIFCruiseMissileLauncher
local EffectTemplate = import("/lua/effecttemplates.lua")

---@class UEB2108 : TStructureUnit
UEB2108 = ClassUnit(TStructureUnit) {
    Weapons = {
        CruiseMissile = ClassWeapon(TIFCruiseMissileLauncher) {
            FxMuzzleFlash = EffectTemplate.TIFCruiseMissileLaunchBuilding,
        },
    },
}

TypeClass = UEB2108

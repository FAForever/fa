-----------------------------------------------------------------
-- File     :  /cdimage/units/URB2108/URB2108_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix
-- Summary  :  Cybran Tactical Missile Launcher Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local CStructureUnit = import('/lua/cybranunits.lua').CStructureUnit
local CIFMissileLoaTacticalWeapon = import('/lua/cybranweapons.lua').CIFMissileLoaTacticalWeapon
local ManualLaunchWeapon = import('/lua/sim/defaultweapons.lua').ManualLaunchWeapon

URB2108 = Class(CStructureUnit) {
    Weapons = {
        CruiseMissile = Class(CIFMissileLoaTacticalWeapon, ManualLaunchWeapon) {},
    },
}

TypeClass = URB2108

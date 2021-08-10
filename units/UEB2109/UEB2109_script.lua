#****************************************************************************
#**
#**  File     :  /cdimage/units/UEB2109/UEB2109_script.lua
#**  Author(s):  John Comes, David Tomandl
#**
#**  Summary  :  Terran Ground-based Torpedo Launcher Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local TStructureUnit = import('/lua/terranunits.lua').TStructureUnit
local TANTorpedoLandWeapon = import('/lua/terranweapons.lua').TANTorpedoLandWeapon

UEB2109 = Class(TStructureUnit) {
    Weapons = {
        Turret01 = Class(TANTorpedoLandWeapon) {},
    },
}

TypeClass = UEB2109


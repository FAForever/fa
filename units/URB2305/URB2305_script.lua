#****************************************************************************
#**
#**  File     :  /cdimage/units/URB2305/URB2305_script.lua
#**  Author(s):  John Comes, David Tomandl
#**
#**  Summary  :  Cybran Strategic Missile Launcher Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local CStructureUnit = import('/lua/cybranunits.lua').CStructureUnit
local CIFMissileStrategicWeapon = import('/lua/cybranweapons.lua').CIFMissileStrategicWeapon

URB2305 = Class(CStructureUnit) {
    Weapons = {
        NukeMissiles = Class(CIFMissileStrategicWeapon) {},
    },
    
}

TypeClass = URB2305

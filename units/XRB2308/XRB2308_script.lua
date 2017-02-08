#****************************************************************************
#**
#**  File     :  /cdimage/units/XRB2205/XRB2205_script.lua
#**  Author(s):  Jessica St. Croix, Gordon Duclos
#**
#**  Summary  :  Cybran Heavy Torpedo Launcher Script
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local CStructureUnit = import('/lua/cybranunits.lua').CStructureUnit
local CKrilTorpedoLauncherWeapon = import('/lua/cybranweapons.lua').CKrilTorpedoLauncherWeapon

XRB2308 = Class(CStructureUnit) {
    Weapons = {
        Turret01 = Class(CKrilTorpedoLauncherWeapon) {},
    },
}
TypeClass = XRB2308
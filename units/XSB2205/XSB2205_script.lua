#****************************************************************************
#**
#**  File     :  /cdimage/units/XSB2205/XSB2205_script.lua
#**  Author(s):  Drew Staltman, Jessica St. Croix, Gordon Duclos
#**
#**  Summary  :  Seraphim Heavy Torpedo Launcher Script
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

XSB2205 = Class(import('/lua/seraphimunits.lua').SStructureUnit) {
    Weapons = {
        TorpedoTurrets = Class(import('/lua/seraphimweapons.lua').SANHeavyCavitationTorpedo) {},
        AjelluTorpedoDefense = Class(import('/lua/seraphimweapons.lua').SDFAjelluAntiTorpedoDefense) {},
    },
}
TypeClass = XSB2205
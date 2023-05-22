--****************************************************************************
--**
--**  File     :  /cdimage/units/XSB2205/XSB2205_script.lua
--**  Author(s):  Drew Staltman, Jessica St. Croix, Gordon Duclos
--**
--**  Summary  :  Seraphim Heavy Torpedo Launcher Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

XSB2205 = ClassUnit(import("/lua/seraphimunits.lua").SStructureUnit) {
    Weapons = {
        TorpedoTurrets = ClassWeapon(import("/lua/seraphimweapons.lua").SANHeavyCavitationTorpedo) {},
        AjelluTorpedoDefense = ClassWeapon(import("/lua/seraphimweapons.lua").SDFAjelluAntiTorpedoDefense) {},
    },
}
TypeClass = XSB2205